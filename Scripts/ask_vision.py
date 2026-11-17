#!/usr/bin/env python3
"""Ask a free vision model about a screenshot or an animation contact sheet.

The key is never stored in the repository: it comes from OPENROUTER_API_KEY or from
the local OpenCode auth file (~/.local/share/opencode/auth.json).

Usage:
    python3 Scripts/ask_vision.py build/screen.png
    python3 Scripts/ask_vision.py build/sheet.png "Is the animation smooth?"
"""

import base64
import json
import os
import sqlite3
import sys
import urllib.error
import urllib.request
from pathlib import Path

ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"
MODELS = [
    "nvidia/nemotron-3.5-super-vl:free",
    "dots-studio/dots-3-note-preview:free",
    "openrouter/free",
]
AUTH_FILES = [
    Path.home() / ".local/share/opencode/auth.json",
    Path.home() / ".config/opencode/auth.json",
]
OPENCODE_DB = Path.home() / ".local/share/opencode/opencode.db"
DEFAULT_PROMPT = (
    "Describe this iOS app screen for a developer review. Cover: 1) layout and hierarchy, "
    "2) spacing, alignment and clipped or overlapping content, 3) contrast and legibility, "
    "4) anything that looks like a visual defect or a placeholder. Be concrete and brief."
)
SHEET_PROMPT = (
    "These are frames sampled from an iOS screen recording, labelled with their index, "
    "timestamp and the gap to the previous frame; red-bordered frames are gaps over 24 ms. "
    "Judge: 1) is the motion smooth or are there jumps, 2) does any text re-wrap, shift or "
    "change width while the keyboard or a transition moves, 3) layout defects, flashes or "
    "misaligned layers, 4) which numbered frames look like the problem. Be concrete and brief."
)


def die(message: str) -> "NoReturn":  # noqa: F821
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def key_from_auth_files() -> str:
    for path in AUTH_FILES:
        if not path.exists():
            continue
        try:
            data = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        entry = data.get("openrouter") or {}
        if isinstance(entry, dict):
            for field in ("key", "apiKey", "api_key"):
                value = entry.get(field)
                if isinstance(value, str) and value.strip():
                    return value.strip()
    return ""


def key_from_opencode_db() -> str:
    """OpenCode v2 keeps provider keys in its local database, not in auth.json."""
    if not OPENCODE_DB.exists():
        return ""
    try:
        connection = sqlite3.connect(f"file:{OPENCODE_DB}?mode=ro", uri=True)
        try:
            row = connection.execute(
                "select value from credential "
                "where integration_id = 'openrouter' and active = 1 "
                "order by time_updated desc limit 1"
            ).fetchone()
        finally:
            connection.close()
    except sqlite3.Error:
        return ""
    if not row or not row[0]:
        return ""
    try:
        value = json.loads(row[0])
    except json.JSONDecodeError:
        return ""
    key = value.get("key") if isinstance(value, dict) else None
    return key.strip() if isinstance(key, str) else ""


def api_key() -> str:
    key = os.environ.get("OPENROUTER_API_KEY", "").strip()
    if key:
        return key
    for candidate in (key_from_auth_files(), key_from_opencode_db()):
        if candidate:
            return candidate
    die(
        "no OpenRouter key. Export OPENROUTER_API_KEY=... or sign in with "
        "`opencode auth login` so the key is stored locally (never in this repository)."
    )


def encode(image: Path) -> str:
    if not image.exists():
        die(f"{image} does not exist")
    return base64.b64encode(image.read_bytes()).decode("ascii")


def request(model: str, key: str, prompt: str, image: Path, payload: str) -> str:
    body = {
        "model": model,
        "max_tokens": 900,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/png;base64,{payload}"},
                    },
                ],
            }
        ],
    }
    http = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://github.com/ephmrl-team/Bloom-iOS",
            "X-Title": "Bloom visual check",
        },
        method="POST",
    )
    with urllib.request.urlopen(http, timeout=120) as response:
        data = json.loads(response.read().decode("utf-8"))
    choices = data.get("choices") or []
    if not choices:
        raise RuntimeError(f"{model} returned no choices: {json.dumps(data)[:300]}")
    message = choices[0].get("message") or {}
    content = message.get("content")
    if isinstance(content, list):
        content = " ".join(
            part.get("text", "") for part in content if isinstance(part, dict)
        )
    text = (content or "").strip()
    if not text:
        raise RuntimeError(f"{model} returned an empty answer")
    return text


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__.strip())
        sys.exit(64)

    image = Path(sys.argv[1])
    prompt = " ".join(sys.argv[2:]).strip()
    if not prompt:
        prompt = SHEET_PROMPT if "sheet" in image.name else DEFAULT_PROMPT

    key = api_key()
    payload = encode(image)
    print(f"image: {image} ({image.stat().st_size // 1024} KB)")

    last_error = ""
    for model in MODELS:
        try:
            answer = request(model, key, prompt, image, payload)
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", "replace")[:200]
            last_error = f"{model}: HTTP {error.code} {detail}"
            print(f"warning: {last_error}", file=sys.stderr)
            continue
        except (urllib.error.URLError, RuntimeError, TimeoutError) as error:
            last_error = f"{model}: {error}"
            print(f"warning: {last_error}", file=sys.stderr)
            continue
        print(f"model: {model}\n")
        print(answer)
        return

    die(f"every vision model failed. Last error: {last_error}")


if __name__ == "__main__":
    main()
