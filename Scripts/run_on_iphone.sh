#!/usr/bin/env bash
#
# Build, install and launch Bloom on the iPhone connected by USB.
# Usage: ./Scripts/run_on_iphone.sh [--debug|--release] [--launch-arg <arg>]... [--launch-args "<args>"]
#   BLOOM_LAUNCH_ARGS="-AppMode=mock" ./Scripts/run_on_iphone.sh
#   ./Scripts/run_on_iphone.sh --launch-arg -AppMode=mock --launch-arg -MockScenario=large
#
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

CONFIGURATION="Debug"
LAUNCH_ARGS=()
LAUNCH_ARGS_RAW="${BLOOM_LAUNCH_ARGS:-}"
while [ $# -gt 0 ]; do
    case "$1" in
        --release) CONFIGURATION="Release" ;;
        --debug) CONFIGURATION="Debug" ;;
        --launch-arg)
            [ $# -ge 2 ] || { echo "error: --launch-arg needs a value" >&2; exit 64; }
            LAUNCH_ARGS+=("$2")
            shift
            ;;
        --launch-args)
            [ $# -ge 2 ] || { echo "error: --launch-args needs a value" >&2; exit 64; }
            LAUNCH_ARGS_RAW="$2"
            shift
            ;;
        -h | --help)
            sed -n '2,7p' "$0"
            exit 0
            ;;
        *)
            echo "error: unknown argument '$1' (use --debug, --release or --launch-arg)" >&2
            exit 64
            ;;
    esac
    shift
done

if [ -n "$LAUNCH_ARGS_RAW" ]; then
    read -r -a ENV_ARGS <<< "$LAUNCH_ARGS_RAW"
    LAUNCH_ARGS+=("${ENV_ARGS[@]}")
fi

BUNDLE_ID="pw.ephmrl.bloom"
DERIVED="build/DerivedData"
DEVICES_JSON="build/devices.json"
mkdir -p build

echo "== Looking for a USB iPhone =="
if ! xcrun devicectl list devices --json-output "$DEVICES_JSON" > /dev/null 2>&1; then
    echo "error: 'xcrun devicectl list devices' failed. Is Xcode 26+ selected (xcode-select -p)?" >&2
    exit 1
fi

DEVICE_LINE=$(python3 - "$DEVICES_JSON" <<'PY'
import json
import sys

devices = json.load(open(sys.argv[1]))["result"]["devices"]
for device in devices:
    hardware = device.get("hardwareProperties", {})
    if hardware.get("reality") != "physical":
        continue
    props = device.get("deviceProperties", {})
    connection = device.get("connectionProperties", {})
    print("\t".join([
        device["identifier"],
        hardware.get("udid") or "",
        hardware.get("marketingName") or "iPhone",
        (props.get("name") or "").strip(),
        connection.get("pairingState") or "",
        props.get("developerModeStatus") or "",
        str(props.get("ddiServicesAvailable")),
    ]))
    break
PY
)

if [ -z "$DEVICE_LINE" ]; then
    cat >&2 <<'MSG'
error: no physical iPhone found.
  - connect the phone with a cable (Wi-Fi debugging is not used here);
  - unlock it and tap "Trust" on the "Trust This Computer?" prompt;
  - make sure Settings > Privacy & Security > Developer Mode is on;
  - re-run this script. The simulator is never used.
MSG
    exit 2
fi

IFS=$'\t' read -r DEVICE_ID UDID MODEL NAME PAIRING DEV_MODE DDI <<< "$DEVICE_LINE"
echo "device: $NAME ($MODEL)"
echo "devicectl id: $DEVICE_ID"

if [ "$PAIRING" != "paired" ]; then
    echo "error: the iPhone is not paired with this Mac (state: $PAIRING). Unlock it and accept the trust prompt." >&2
    exit 3
fi
if [ "$DEV_MODE" != "enabled" ]; then
    echo "error: Developer Mode is off on the iPhone (Settings > Privacy & Security > Developer Mode)." >&2
    exit 4
fi
if [ "$DDI" != "True" ]; then
    echo "warning: developer disk image services are not available; unlock the phone and keep it connected." >&2
fi

if [ -z "$UDID" ]; then
    echo "== Resolving the hardware UDID from xcodebuild =="
    UDID=$(xcodebuild -project Bloom.xcodeproj -scheme Bloom -showdestinations 2> /dev/null \
        | sed -n 's/.*platform:iOS, arch:[^,]*, id:\([0-9A-Fa-f-]\{20,\}\).*/\1/p' | head -1)
fi
if [ -z "$UDID" ]; then
    echo "error: could not resolve the device UDID for xcodebuild." >&2
    exit 5
fi
echo "build destination: id=$UDID"

echo "== Building $CONFIGURATION =="
xcodebuild -project Bloom.xcodeproj -scheme Bloom \
    -configuration "$CONFIGURATION" \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED" \
    -allowProvisioningUpdates \
    build

APP_PATH="$DERIVED/Build/Products/$CONFIGURATION-iphoneos/Bloom.app"
if [ ! -d "$APP_PATH" ]; then
    APP_PATH=$(find "$DERIVED/Build/Products" -maxdepth 2 -name "Bloom.app" -type d | head -1)
fi
if [ -z "${APP_PATH:-}" ] || [ ! -d "$APP_PATH" ]; then
    echo "error: Bloom.app was not found under $DERIVED/Build/Products." >&2
    exit 6
fi
echo "app: $APP_PATH"

echo "== Installing =="
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "== Launching $BUNDLE_ID =="
LAUNCH_CMD=(xcrun devicectl device process launch --device "$DEVICE_ID" --terminate-existing "$BUNDLE_ID")
if [ ${#LAUNCH_ARGS[@]} -gt 0 ]; then
    echo "launch arguments: ${LAUNCH_ARGS[*]}"
    LAUNCH_CMD+=("${LAUNCH_ARGS[@]}")
fi
"${LAUNCH_CMD[@]}"

echo "done: Bloom is running on $NAME"
