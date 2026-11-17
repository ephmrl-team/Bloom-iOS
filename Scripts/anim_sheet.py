#!/usr/bin/env python3
"""Turn an iPhone screen recording into a contact sheet with real frame timings.

Frames are sampled from ffprobe's own timestamps, scaled to a readable grid and
labelled with their index and timestamp. A gap longer than 24 ms between two
sampled frames is drawn with a red border — that is where the UI visibly stalls.

Usage:
    python3 Scripts/anim_sheet.py --video build/capture.mov --out build/sheet.png
    python3 Scripts/anim_sheet.py --record 4 --out build/sheet.png
"""

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

MAX_FRAMES = 18
COLUMNS = 3
THUMB_WIDTH = 340
SLOW_FRAME_MS = 24.0
LABEL_HEIGHT = 26


def die(message: str) -> "NoReturn":  # noqa: F821 - typing kept simple for py_compile
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def require_tools() -> None:
    if shutil.which("ffmpeg") is None:
        die(
            "missing ffmpeg.\n"
            "  Install it with: brew install ffmpeg\n"
            "  (or: python3 -m pip install --user imageio-ffmpeg, then copy its binary to /usr/local/bin/ffmpeg)"
        )
    try:
        from PIL import Image  # noqa: F401
    except ImportError:
        die("missing Pillow.\n  Install it with: python3 -m pip install --user Pillow")


def frame_times(video: Path) -> list[float]:
    """Real presentation timestamps: ffprobe when available, otherwise ffmpeg's showinfo."""
    if shutil.which("ffprobe"):
        result = subprocess.run(
            [
                "ffprobe", "-v", "error", "-select_streams", "v:0",
                "-show_entries", "frame=pts_time", "-of", "csv=p=0", str(video),
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            die(f"ffprobe failed: {result.stderr.strip()[:400]}")
        times = []
        for line in result.stdout.splitlines():
            line = line.strip().strip(",")
            if not line:
                continue
            try:
                times.append(float(line))
            except ValueError:
                continue
        if times:
            return sorted(times)

    result = subprocess.run(
        ["ffmpeg", "-v", "info", "-i", str(video), "-vf", "showinfo", "-f", "null", "-"],
        capture_output=True,
        text=True,
        check=False,
    )
    times = [float(match) for match in re.findall(r"pts_time:\s*([0-9.]+)", result.stderr)]
    if not times:
        die("no video frames found in " + str(video))
    return sorted(times)


def sample_indices(count: int, limit: int = MAX_FRAMES) -> list[int]:
    if count <= limit:
        return list(range(count))
    step = count / limit
    return sorted({min(count - 1, int(index * step)) for index in range(limit)})


def interval_ms(times: list[float], index: int) -> float:
    """How long the frame itself lasted: the gap from the previous source frame."""
    if len(times) < 2:
        return 0.0
    if index == 0:
        return (times[1] - times[0]) * 1000
    return (times[index] - times[index - 1]) * 1000


def grab(video: Path, timestamp: float, destination: Path) -> Path:
    subprocess.run(
        [
            "ffmpeg", "-v", "error", "-y", "-ss", f"{timestamp:.3f}", "-i", str(video),
            "-frames:v", "1", "-vf", f"scale={THUMB_WIDTH}:-1", str(destination),
        ],
        check=False,
    )
    return destination


def record(seconds: float, out: Path) -> Path:
    capture = Path("build/device-capture")
    source = Path("Scripts/DeviceCapture.swift")
    plist = Path("Scripts/DeviceCapture-Info.plist")
    if not capture.exists() or capture.stat().st_mtime < max(
        source.stat().st_mtime, plist.stat().st_mtime
    ):
        print("building build/device-capture ...")
        # Embedded Info.plist: without NSCameraUsageDescription TCC denies camera access.
        subprocess.run(
            [
                "swiftc",
                "-O",
                str(source),
                "-o",
                str(capture),
                "-Xlinker",
                "-sectcreate",
                "-Xlinker",
                "__TEXT",
                "-Xlinker",
                "__info_plist",
                "-Xlinker",
                str(plist),
            ],
            check=False,
        )
    if not capture.exists():
        die("could not build build/device-capture")
    movie = out.parent / "capture.mov"
    subprocess.run([str(capture), "--record", str(seconds), str(movie)], check=False)
    if not movie.exists():
        die(f"recording failed, expected {movie}")
    return movie


def build_sheet(frames: list[tuple[Path, float, float]], out: Path) -> None:
    from PIL import Image, ImageDraw

    tiles = []
    for path, timestamp, gap_ms in frames:
        with Image.open(path) as image:
            tile = image.convert("RGB")
        canvas = Image.new("RGB", (tile.width, tile.height + LABEL_HEIGHT), "white")
        canvas.paste(tile, (0, LABEL_HEIGHT))
        draw = ImageDraw.Draw(canvas)
        label = f"#{len(tiles) + 1}  t={timestamp:.2f}s  +{gap_ms:.0f}ms"
        draw.text((6, 6), label, fill="red" if gap_ms > SLOW_FRAME_MS else "black")
        if gap_ms > SLOW_FRAME_MS:
            draw.rectangle(
                [0, LABEL_HEIGHT, tile.width - 1, tile.height + LABEL_HEIGHT - 1],
                outline="red",
                width=3,
            )
        tiles.append(canvas)

    columns = min(COLUMNS, len(tiles))
    rows = (len(tiles) + columns - 1) // columns
    cell_width = max(tile.width for tile in tiles)
    cell_height = max(tile.height for tile in tiles)
    sheet = Image.new("RGB", (cell_width * columns, cell_height * rows), "#e8e8ec")

    for index, tile in enumerate(tiles):
        column = index % columns
        row = index // columns
        sheet.paste(tile, (column * cell_width, row * cell_height))

    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    slow = [index + 1 for index, (_, _, gap) in enumerate(frames) if gap > SLOW_FRAME_MS]
    print(f"saved {out} ({len(tiles)} frames, {columns}x{rows})")
    if slow:
        print("slow frames (frame lasted more than " + f"{SLOW_FRAME_MS:.0f}ms): {slow}")
    else:
        print("every sampled frame stayed under " + f"{SLOW_FRAME_MS:.0f}ms")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build an animation contact sheet.")
    parser.add_argument("--video", help="existing recording (.mov/.mp4)")
    parser.add_argument("--record", type=float, help="record this many seconds from the USB iPhone")
    parser.add_argument("--out", default="build/sheet.png")
    parser.add_argument("--frames", type=int, default=MAX_FRAMES)
    args = parser.parse_args()

    require_tools()
    out = Path(args.out)

    if args.video:
        video = Path(args.video)
    elif args.record:
        video = record(args.record, out)
    else:
        parser.error("pass --video <file> or --record <seconds>")

    if not video.exists():
        die(f"{video} does not exist")

    times = frame_times(video)
    indices = sample_indices(len(times), max(2, args.frames))
    print(f"{video}: {len(times)} frames, {len(indices)} sampled")

    frames: list[tuple[Path, float, float]] = []
    with tempfile.TemporaryDirectory() as directory:
        temp = Path(directory)
        for position, index in enumerate(indices):
            timestamp = times[index]
            path = grab(video, timestamp, temp / f"frame-{position:02d}.png")
            if not path.exists():
                continue
            frames.append((path, timestamp, interval_ms(times, index)))
        if not frames:
            die("could not extract any frame")
        build_sheet(frames, out)


if __name__ == "__main__":
    main()
