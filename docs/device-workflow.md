# Device workflow (USB iPhone, no simulator)

Everything runs on the physical iPhone. The simulator is broken on this Mac and is never used.

## One-time setup

1. Connect the iPhone by cable, unlock it, tap "Trust".
2. Xcode → Settings → Accounts: the team must be able to sign `pw.ephmrl.bloom`.
3. Grant the terminal (Terminal/iTerm/opencode) **Camera**, **Screen Recording** and **Accessibility** in
   System Settings → Privacy & Security, then restart the terminal. Without Camera/Screen Recording the
   capture tool cannot see the iPhone video stream.
4. `BloomKit.xcframework` must sit in the repository root — the app does not link without it.
5. Tools used by the visual loop: `brew install ffmpeg` (or `python3 -m pip install --user imageio-ffmpeg`
   and copy its binary to `/usr/local/bin/ffmpeg`), `python3 -m pip install --user Pillow`,
   `brew install swiftformat swiftlint`.

## Build, install, launch

```bash
./Scripts/run_on_iphone.sh            # finds the phone, builds Debug, installs, launches
./Scripts/run_on_iphone.sh --release  # same with -configuration Release

# open a specific screen: launch arguments are passed through to the app
./Scripts/run_on_iphone.sh --launch-arg -AppMode=mock --launch-arg -MockScenario=large
BLOOM_LAUNCH_ARGS="-AppMode=mock" ./Scripts/run_on_iphone.sh
```

The script prints the device UDID and the `devicectl` identifier it picked, the built `Bloom.app` path, and
stops with a readable message when the phone is unplugged, locked or untrusted.

## Visual checks

```bash
./Scripts/visual_check.sh screen         # screenshot -> build/screen.png -> vision review
./Scripts/visual_check.sh screen --run   # build/install/launch first, then the same
./Scripts/visual_check.sh anim 4         # record 4 s -> build/sheet.png -> smoothness review
```

- `Scripts/DeviceCapture.swift` is a small macOS CLI compiled on demand into `build/device-capture`; it turns on
  CoreMediaIO's screen-capture devices so AVFoundation sees the iPhone without opening QuickTime. The phone is
  an `.external` device with the `.muxed` media type, so give it a few seconds and keep the screen awake —
  a locked phone disappears from the list. `Scripts/DeviceCapture-Info.plist` is linked into the binary for
  `NSCameraUsageDescription`; `--list` prints every visible device with its type and model.
- `Scripts/anim_sheet.py` turns a recording into a contact sheet with real frame timestamps and flags frames
  longer than 24 ms (dropped frames).
- `Scripts/ask_vision.py` sends the PNG to a free vision model through OpenRouter; the key is read from
  `OPENROUTER_API_KEY` or the local OpenCode credential store, never from the repository.
- Artefacts (`build/screen.png`, `build/sheet.png`, `build/capture.mov`, `build/device-capture`) are all under
  `build/`, which is git-ignored.

Before reporting work run `./Scripts/verify.sh` (AGENTS.md length, file sizes, security audit, swiftformat,
swiftlint, Debug and strict-concurrency builds); it must exit 0.
