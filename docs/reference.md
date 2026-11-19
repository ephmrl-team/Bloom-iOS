# Bloom — reference notes

Optional detail behind [`AGENTS.md`](../AGENTS.md). Nothing here overrides the invariants there; this file
exists so the rules loaded in every session stay short.

## Toolchain facts

- Xcode 26+, deployment target iOS 26.0 (project-level setting 26.2, overridden per target), iPhone and iPad
  (`TARGETED_DEVICE_FAMILY = "1,2"`).
- `SWIFT_VERSION = 5.0`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`,
  `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`, `ENABLE_USER_SCRIPT_SANDBOXING = YES`.
- Debug builds with `-Onone`; Release uses whole-module optimization. The shared scheme's Run action uses
  the Release configuration, so `#if DEBUG` code does not execute on a normal run.
- Dependencies: `Bip39.swift`, `BlurUIKit`/`BlurSwiftUI`, `swift-collections` (`Deque`), and the binary
  `BloomKit.xcframework` (not in the repository, must be placed in the repo root to build).
- `Bloom.xctestplan` holds two configurations: **Default** (unit + UI tests) and **Performance**
  (launch and scroll metrics, disabled by default).

## Commands

```bash
# Release build
xcodebuild -project Bloom.xcodeproj -scheme Bloom \
  -destination 'generic/platform=iOS' -configuration Release CODE_SIGNING_ALLOWED=NO build

# Static analyzer
xcodebuild -project Bloom.xcodeproj -scheme Bloom -destination 'generic/platform=iOS' analyze

# Tests (physical device only; list devices first)
xcrun devicectl list devices
xcodebuild -project Bloom.xcodeproj -scheme Bloom -showdestinations
xcodebuild test -project Bloom.xcodeproj -scheme Bloom \
  -destination 'platform=iOS,id=<DEVICE ID>' -enableCodeCoverage YES \
  -resultBundlePath build/TestResults.xcresult

# Sanitizers (ASan and TSan cannot be combined)
xcodebuild test -project Bloom.xcodeproj -scheme Bloom \
  -destination 'platform=iOS,id=<DEVICE ID>' \
  -enableAddressSanitizer YES -enableUndefinedBehaviorSanitizer YES
xcodebuild test -project Bloom.xcodeproj -scheme Bloom \
  -destination 'platform=iOS,id=<DEVICE ID>' -enableThreadSanitizer YES
```

Verifying that an iOS 26 symbol exists before using it:

```bash
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
grep -n "<symbolName>" $(find "$SDK/System/Library/Frameworks/SwiftUI.framework" \
  -name 'arm64e-apple-ios.swiftinterface')
grep -rn "<symbolName>" "$SDK/System/Library/Frameworks/UIKit.framework/Headers"
```

## CI

`.github/workflows/ci.yml` runs on `macos-26`:

1. `static-checks` — `./Scripts/check-file-size.sh`, `./Scripts/security-audit.sh`, `swiftlint lint --strict`.
2. `build-and-test` — Debug build, strict-concurrency build, then `BloomTests` on a simulator. The whole job
   is skipped when `BloomKit.xcframework/Info.plist` is missing, because the app cannot link without it.

Simulator use is allowed inside CI only. Locally, every build, test and profile run targets a physical device.

## Performance budgets

| Metric | Budget |
|---|---|
| Frame time on ProMotion devices | ≤ 8.3 ms, never > 16.6 ms in steady state |
| Hitch time ratio during scroll/transitions | < 5 ms/s |
| Cold launch to first interactive frame | record a baseline, no regression > 10 % |
| Main-thread hang | none ≥ 250 ms |
| Memory during a 60 s scripted chat scroll | no unbounded growth, no leaks |

Measure with Instruments (SwiftUI, Time Profiler, Hangs, Hitches, Allocations, Leaks) on a physical device in
Release without a debugger attached, and with `XCTClockMetric`, `XCTCPUMetric`, `XCTMemoryMetric`,
`XCTHitchMetric`, `XCTOSSignpostMetric` and `XCTApplicationLaunchMetric` in `BloomPerformanceTests`.
Store baselines in `BloomPerformanceTests/Baselines/` and note device model, OS and Xcode version.

SwiftUI specifics: no sorting, filtering or formatting in `body`; stable `Identifiable` ids in `ForEach`;
`LazyVStack`/`List` for long collections; no `AnyView`; pass values instead of whole stores; animate
compositor-only properties (opacity, offset, scale) rather than layout sizes; use `Canvas`/`drawingGroup` for
heavy drawing; decode and downsample images off the main thread.

## UIKit and Objective-C policy

Default to Swift and SwiftUI. Use UIKit (in Swift, via `UIViewRepresentable`) when SwiftUI cannot meet the
budget or lacks the API — precedent: `Features/Chat/ChatFooter/KeyboardTrackerHost.swift`. Use Objective-C only for a measured
CPU-bound hot loop, in `Bloom/Native/`, with class prefix `BLM`, ARC, `NS_ASSUME_NONNULL_BEGIN`, lightweight
generics, no per-call allocation and `os_log` with `%{private}`.

A replacement is accepted only with a before/after measurement on a physical device, a Release build, an
improvement of ≥ 15 % on the target metric (or ≥ 1 ms per frame at p95), and a committed performance test.
Candidates worth measuring, not assumed wins: audio level processing, hex/byte conversions, hashing and
diffing large message arrays, per-frame `CALayer` updates, keyboard-driven layouts.

## Security detail

- `Helpers/KeychainHelper.swift` currently writes `kSecClassGenericPassword` items without an explicit
  accessibility attribute and prints `OSStatus` values. Treat it as a known weakness: any new or modified
  write must set `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, avoid `kSecAttrSynchronizable`, use
  `SecItemUpdate` for atomic updates, return typed errors, and use a distinct service name in tests.
- No biometric gate exists. If one is added: `LAContext`, `INFOPLIST_KEY_NSFaceIDUsageDescription`,
  `SecAccessControl` with `.biometryCurrentSet`, explicit `LAError` handling, re-lock on backgrounding.
- Files with user data use `FileProtectionType.complete`; audio recordings live in the temporary directory
  and are deleted after send or cancel.
- Every change to secrets, storage, networking or input parsing needs tests in `BloomTests/` (Swift Testing):
  Keychain attributes and round trip, mnemonic validation, hostile JSON decoding, and no secret in logs.

## Testing notes

- Unit tests are deterministic and fast (< 100 ms), with no network, no production Keychain service name and
  no real clock or randomness — inject small protocols.
- `BloomKit` access goes behind a protocol (`Bloom/State/API/BloomAPI.swift`) so tests use `FakeAPI`.
- UI tests use accessibility identifiers, never display text. Coverage target for new non-UI logic: ≥ 80 %.

## Commit messages

Single-line subject, English, imperative mood, capitalized first word (`Add`, `Fix`, `Show`, `Split`,
`Remove`…), ≤ 72 characters, no trailing period, no Conventional Commits prefixes, no ticket numbers. Use the
body (blank line, wrapped at 72 columns, bullets with `-`) only for the reason behind a non-obvious change,
verification commands, before/after numbers, or what was not verified.

## Dependencies and history

- Prefer the platform SDK. A new package needs maintainer approval, a version range, a GPLv3-compatible
  license and a note about the data it can access.
- Do not commit `DerivedData/`, `build/`, `*.xcuserstate`, `xcuserdata/`, `*.xcresult`, signing material or
  `BloomKit.xcframework`. Commit `Package.resolved` when it changes.
- Known stale spots: `README.md` used to claim Swift 6.0 and Face ID protection; the code is Swift 5.0 with
  no biometric gate.
