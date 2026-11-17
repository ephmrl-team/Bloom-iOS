#!/usr/bin/env bash
#
# Visual checks on the USB iPhone: screenshot or animation contact sheet, reviewed by a vision model.
# Usage: ./Scripts/visual_check.sh screen [--run]
#        ./Scripts/visual_check.sh anim [seconds]
#
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

CAPTURE="build/device-capture"
BUNDLE_ID="pw.ephmrl.bloom"
mkdir -p build

die() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

build_capture() {
    if [ -x "$CAPTURE" ] && [ "$CAPTURE" -nt Scripts/DeviceCapture.swift ] \
        && [ "$CAPTURE" -nt Scripts/DeviceCapture-Info.plist ]; then
        return
    fi
    echo "== Building $CAPTURE =="
    # The embedded Info.plist gives the CLI its NSCameraUsageDescription; without it TCC denies access.
    swiftc -O Scripts/DeviceCapture.swift -o "$CAPTURE" \
        -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist \
        -Xlinker Scripts/DeviceCapture-Info.plist \
        || die "DeviceCapture.swift does not compile"
}

python3 -c 'import PIL' 2> /dev/null || die "Pillow is missing: python3 -m pip install --user Pillow"

MODE="${1:-screen}"
case "$MODE" in
    screen)
        build_capture
        if [ "${2:-}" = "--run" ]; then
            ./Scripts/run_on_iphone.sh || die "could not build, install and launch the app"
            sleep 3
        fi
        echo "== Screenshot =="
        "$CAPTURE" --screenshot build/screen.png || die "capture failed (see the permission hints above)"
        python3 Scripts/ask_vision.py build/screen.png
        ;;
    anim)
        SECONDS_TO_RECORD="${2:-4}"
        build_capture
        command -v ffmpeg > /dev/null 2>&1 || die "ffmpeg is missing: brew install ffmpeg"
        echo "== Recording ${SECONDS_TO_RECORD}s =="
        "$CAPTURE" --record "$SECONDS_TO_RECORD" build/capture.mov \
            || die "recording failed (see the permission hints above)"
        echo "== Building contact sheet =="
        python3 Scripts/anim_sheet.py --video build/capture.mov --out build/sheet.png \
            || die "anim_sheet.py failed"
        python3 Scripts/ask_vision.py build/sheet.png \
            "These are frames from an iOS screen recording, labelled with index, timestamp and the gap to the previous frame; red-bordered frames are gaps over 24 ms. Judge smoothness, text jumps or re-wrapping, and UI defects. Name the frame numbers that show a problem."
        ;;
    *)
        sed -n '2,6p' "$0"
        exit 64
        ;;
esac
