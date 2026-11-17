#!/usr/bin/env bash
#
# One gate for the whole project: docs, sizes, security, format, lint and builds.
# Usage: ./Scripts/verify.sh            (exit 0 = everything passes)
#
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

fail=0
step() { printf '\n== %s ==\n' "$1"; }
fail_step() { printf 'FAIL: %s\n' "$1"; fail=1; }

step "AGENTS.md length"
lines=$(wc -l < AGENTS.md | tr -d ' ')
if [ "$lines" -le 75 ]; then
    echo "AGENTS.md: $lines lines (limit 75)"
else
    echo "AGENTS.md: $lines lines, limit is 75"
    fail_step "AGENTS.md length"
fi

step "File size limits"
./Scripts/check-file-size.sh || fail_step "check-file-size.sh"

step "Security audit"
./Scripts/security-audit.sh || fail_step "security-audit.sh"

step "SwiftFormat"
if command -v swiftformat > /dev/null 2>&1; then
    swiftformat --lint Bloom || fail_step "swiftformat --lint Bloom"
else
    echo "warning: swiftformat is not installed (brew install swiftformat), skipping"
fi

step "SwiftLint"
if command -v swiftlint > /dev/null 2>&1; then
    swiftlint lint --strict || fail_step "swiftlint lint --strict"
else
    echo "warning: swiftlint is not installed (brew install swiftlint), skipping"
fi

mkdir -p build
# build <label> [extra xcodebuild settings...]
build() {
    local label=$1
    shift
    local log="build/verify-$label.log"
    step "Build: $label"
    if xcodebuild -project Bloom.xcodeproj -scheme Bloom \
        -destination 'generic/platform=iOS' \
        -configuration Debug CODE_SIGNING_ALLOWED=NO "$@" build > "$log" 2>&1; then
        echo "BUILD SUCCEEDED ($label), log: $log"
        grep -E "warning:" "$log" | grep -v appintentsmetadataprocessor | sort -u | head -10
    else
        echo "BUILD FAILED ($label), log: $log"
        grep -E "error:" "$log" | sort -u | head -20
        fail_step "build $label"
    fi
}

build debug
build strict SWIFT_STRICT_CONCURRENCY=complete

printf '\n== Result ==\n'
if [ "$fail" -eq 0 ]; then
    echo "verify.sh: all checks passed"
else
    echo "verify.sh: failures above"
fi
exit "$fail"
