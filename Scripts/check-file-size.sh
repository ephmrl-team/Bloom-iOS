#!/usr/bin/env bash
# Fails when a Swift/Objective-C source file grows past the hard limit in AGENTS.md §5.2.
# Files listed in Scripts/file-size-allowlist.txt are reported but do not fail the check.
set -euo pipefail

LIMIT=250
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ALLOWLIST="$ROOT/Scripts/file-size-allowlist.txt"

is_allowed() {
  [ -f "$ALLOWLIST" ] && grep -qxF "$1" "$ALLOWLIST"
}

fail=0
while IFS= read -r file; do
  line_count=$(wc -l < "$file" | tr -d ' ')
  relative="${file#"$ROOT"/}"
  if [ "$line_count" -gt "$LIMIT" ]; then
    if is_allowed "$relative"; then
      echo "ALLOWED ($line_count > $LIMIT): $relative"
    else
      echo "TOO LONG ($line_count > $LIMIT): $relative"
      fail=1
    fi
  fi
done < <(find "$ROOT/Bloom" "$ROOT/BloomTests" "$ROOT/BloomUITests" "$ROOT/BloomPerformanceTests" \
  -type f \( -name '*.swift' -o -name '*.m' -o -name '*.h' \) 2>/dev/null)

exit $fail
