# AGENTS.md — Bloom iOS

Instructions for AI coding agents (and humans) working in this repository.
Read this whole file before changing code. If a rule here conflicts with an explicit instruction from the maintainer in the current task, the maintainer wins; say so in your reply.

---

## 0. How to read this document

Every statement below is one of two kinds:

- **[Fact]** — verified against the repository at the time this file was written (branch `main`, latest commit `3107366 "Change parse chats function"`). Facts can go stale. Re-check with the commands in §3 before relying on one.
- **[Rule]** — a requirement that applies to all work from now on.

Never invent APIs, build settings, files or project history. If you do not know something, write "I don't know" and say how it can be verified. Do not present a guess as a fact.

---

## 1. Project snapshot

### 1.1 Facts

- **[Fact]** Bloom is an iOS messaging app (App Store category: social networking). Bundle ID: `pw.ephmrl.bloom`. Display name: `Bloom`. Single app target `Bloom`, single shared scheme `Bloom`.
- **[Fact]** Deployment target on the app target: **iOS 26.0** (project-level setting is 26.2, target-level overrides it with 26.0). Devices: iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- **[Fact]** UI: SwiftUI, with a custom navigation layer (`Navigation/Router.swift`, `NavigationPath`-based, plus `ModalRoute` for sheets) and UIKit interop where SwiftUI is insufficient (e.g. `Components/UIKitContextMenu.swift`).
- **[Fact]** State: Swift Observation (`@Observable`), injected through `.environment(...)` in `App/BloomApp.swift` (`AppState`, `BloomManager`).
- **[Fact]** Build settings: `SWIFT_VERSION = 5.0`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`, `ENABLE_USER_SCRIPT_SANDBOXING = YES`, `CLANG_ENABLE_MODULES = YES`. Debug: `-Onone`. Release: `SWIFT_COMPILATION_MODE = wholemodule`. The shared scheme's **Run** action uses the **Release** configuration.
- **[Fact]** Sources live in a file-system-synchronized group (`PBXFileSystemSynchronizedRootGroup`): files added under `Bloom/` are picked up by Xcode automatically.
- **[Fact]** Info.plist is generated (`GENERATE_INFOPLIST_FILE = YES`); `Bloom/Info.plist` is an empty dict. Only `NSMicrophoneUsageDescription` is set via `INFOPLIST_KEY_*`.
- **[Fact]** SPM dependencies in `project.pbxproj`: `Bip39.swift` (tesseract-one, ≥ 0.2.0), `BlurUIKit` (TimOliver, ≥ 1.5.0; products `BlurUIKit` and `BlurSwiftUI`), `swift-collections` (apple, ≥ 1.6.0; product `DequeModule`).
- **[Fact]** `BloomManager.swift` does `import BloomKit` and calls `ClientNewClient(...)`, `ClientEditRequest()`, and conforms to `Client*ListenerProtocol` types. `BloomKit.xcframework` is listed in `.gitignore` and is **not in the repository**; `project.pbxproj` contains no reference to it. I do not know how it is linked locally. Without it the project does not compile. Ask the maintainer before touching anything related to it.
- **[Fact]** No test target, no `.xctestplan`, no `Package.swift`, no SwiftLint/SwiftFormat config, no CI workflows, no `.metal` files and no Objective-C files exist on `main`.
- **[Fact]** ~48 Swift files, ~3.7k lines. Largest: `State/Models/BloomManagerModels.swift` (361 lines), `State/BloomManager.swift` (340), `Components/UIKitContextMenu.swift` (232).

### 1.2 Known discrepancies (do not "fix" silently — report them)

- `README.md` says Swift 6.0; `project.pbxproj` says `SWIFT_VERSION = 5.0`. The build setting is what the compiler uses.
- `README.md` lists `LiquidGlassKit` and `lottie-spm`, and mentions `.metal` shaders and `KeyboardPinnedView`. None of these are in the project file or file tree on `main`. Treat the README as aspirational until verified.
- `README.md` says FaceID is required at launch. No `LAContext` / `LocalAuthentication` usage and no `NSFaceIDUsageDescription` exist on `main`.
- `README.md` clone URL points to `slipe-fun/Bloom-iOS`; the repository is `ephmrl-team/Bloom-iOS`.
- `Extensions/EnviromentValues+Namespace.swift` has a typo in the file name ("Enviroment"). Do not rename it unless asked.
- `Helpers/KeychainHelper.swift` has a stale file header (`KeyChainHelper.swift`, project `bloomkittest`).

---

## 2. Absolute rules (read first)

1. **Minimum OS is iOS 26.0.** Write code for iOS 26+ only. Do not add `#available(iOS …)` / `@available(iOS …)` checks for versions ≤ 26.0, and do not write compatibility shims for older systems. Adopt iOS 26 APIs (Liquid Glass, new SwiftUI APIs) directly.
2. **Never invent an API.** If you are not certain a symbol exists in the iOS 26 SDK with that exact signature, verify it (§3.4) or say you are not sure. A compile error caused by a made-up API is a failure.
3. **Small, precise edits.** Change only what the task requires. Do not rewrite, reformat or rename unrelated code. No drive-by refactors; list them as suggestions instead.
4. **Small files.** One primary type per file, hard size limits in §5.2. Extract subviews and helpers into their own files.
5. **Build before you claim success.** A change is "done" only after the build in §3.1 succeeds with zero new warnings. If you cannot build (e.g. no Xcode, no `BloomKit.xcframework`), say so explicitly and say what is unverified.
6. **Security is not optional.** Follow §8. Never log secrets, never weaken Keychain/biometric handling, never add a network or storage path without reviewing it against §8.
7. **Measure before optimizing.** Performance claims need numbers from §9. Objective-C and UIKit are allowed — and encouraged — where measurement shows a win (§10), not by default.
8. **Be honest in the final report.** State what you changed, what you ran, what passed, what you could not run, and anything you assumed.
9. **Never use the iOS Simulator. Always use a physical device.** The maintainer's simulators are broken. Every run, test, UI test, sanitizer run, profiling session and performance measurement goes to a connected physical iPhone/iPad. The only exception: the maintainer's prompt for the current task explicitly asks you to use a simulator. A general wish to "test it" is not such a request. If no physical device is connected or reachable, **stop and ask**; do not fall back to a simulator, and do not claim the work was tested. Compile-only builds use `generic/platform=iOS` (a device destination that needs no connected device and does not involve any simulator).
10. **Never remove the top ProgressiveBlur.** `topVariableBlur()` (the BlurUIKit `VariableBlur` in `ChatListModifiers.swift`) is required on every screen whose header or footer floats over scrolling content. Keep it instead of an opaque fill or a native `scrollEdgeEffectStyle`; do not delete or replace it. (Maintainer instruction, 2026-11-16.)

---

## 3. Commands

All commands run from the repository root on macOS with Xcode 26.0+.

**Device policy (see §2, rule 9):** no command in this file may target a simulator unless the maintainer's current prompt explicitly asks for it. Running, testing and profiling use a connected physical device. List what is connected with:

```bash
xcrun devicectl list devices
xcodebuild -project Bloom.xcodeproj -scheme Bloom -showdestinations
```

Use the identifier shown by `-showdestinations` as `<DEVICE ID>` below. If no physical device is listed, stop and ask the maintainer.

### 3.1 Build

```bash
xcodebuild -project Bloom.xcodeproj -scheme Bloom \
  -destination 'generic/platform=iOS' \
  -configuration Debug build
```

Release build (matches how the scheme's Run action is configured):

```bash
xcodebuild -project Bloom.xcodeproj -scheme Bloom \
  -destination 'generic/platform=iOS' \
  -configuration Release build CODE_SIGNING_ALLOWED=NO
```

Strict-concurrency check (run before any concurrency-related change is declared done):

```bash
xcodebuild -project Bloom.xcodeproj -scheme Bloom \
  -destination 'generic/platform=iOS' \
  SWIFT_STRICT_CONCURRENCY=complete build
```

Static analyzer:

```bash
xcodebuild -project Bloom.xcodeproj -scheme Bloom \
  -destination 'generic/platform=iOS' analyze
```

### 3.2 Tests (after the targets in §7 exist)

All tests run on the connected physical device (get `<DEVICE ID>` as described above; the device must be unlocked and trusted):

```bash
xcodebuild test -project Bloom.xcodeproj -scheme Bloom \
  -destination 'platform=iOS,id=<DEVICE ID>' \
  -enableCodeCoverage YES \
  -resultBundlePath build/TestResults.xcresult
```

Sanitizers (ASan and TSan cannot be combined — run separately):

```bash
xcodebuild test -project Bloom.xcodeproj -scheme Bloom \
  -destination 'platform=iOS,id=<DEVICE ID>' \
  -enableAddressSanitizer YES -enableUndefinedBehaviorSanitizer YES

xcodebuild test -project Bloom.xcodeproj -scheme Bloom \
  -destination 'platform=iOS,id=<DEVICE ID>' \
  -enableThreadSanitizer YES
```

Performance tests run on the **physical device** in Release-like conditions (§9):

```bash
xcodebuild test -project Bloom.xcodeproj -scheme Bloom \
  -destination 'platform=iOS,id=<DEVICE ID>' \
  -only-testing:BloomPerformanceTests
```

### 3.3 Lint / format / repo checks (after §5.4 files exist)

```bash
swiftlint lint --strict
swiftformat --lint Bloom
./Scripts/check-file-size.sh
./Scripts/security-audit.sh
```

### 3.4 Verifying an iOS 26 API actually exists

```bash
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
# Swift-facing declarations (SwiftUI example):
find "$SDK/System/Library/Frameworks/SwiftUI.framework" -name '*.swiftinterface' | head
grep -n "<symbolName>" $(find "$SDK/System/Library/Frameworks/SwiftUI.framework" -name 'arm64e-apple-ios.swiftinterface')
# Objective-C headers (UIKit example):
grep -rn "<symbolName>" "$SDK/System/Library/Frameworks/UIKit.framework/Headers"
```

If the symbol is not found, do not use it. Report the gap and propose a public-API alternative.

---

## 4. Repository layout and conventions

### 4.1 Current layout [Fact]

```
Bloom/
  App/          BloomApp, RootView, ContentView, AuthFlow
  Navigation/   Router, Route, AppState
  State/        BloomManager, MessagesStore, AudioRecorderManager, Models/
  Core/         Theme (spacing, radius, borderWidth, colors, typography)
  Constants/    AvatarConstants
  Components/   reusable views (AvatarView, UIKitContextMenu)
  Extensions/   Type+Purpose.swift files
  Helpers/      KeychainHelper, AvatarGradient, Initials
  Features/     Auth/{AuthWelcome,AuthMnemonic,AuthSuccess}, Chat/{ChatFooter}, ChatList/{ChatListRow}, NewMessage, Profile, Settings
  Assets.xcassets
Bloom.xcodeproj
```

### 4.2 Rules for placing code

- **Feature code** goes in `Features/<Feature>/`. A feature with more than one view gets one subfolder per sub-screen or sub-area (existing examples: `Auth/AuthMnemonic/`, `Chat/ChatFooter/`).
- **View naming:** `<Feature><Part>View.swift` (`AuthMnemonicFooterView`, `ChatListRowPreviewView`). View modifiers: `<Feature>Modifiers.swift` or `<Name>Modifier.swift`. Toolbars: `<Feature>Toolbar.swift`.
- **Reusable UI** used by two or more features → `Components/`. Single-feature UI stays in its feature folder.
- **Extensions** → `Extensions/<Type>+<Purpose>.swift`. Never put an extension of a system type inside an unrelated file (note: `BloomManager.swift` currently contains `extension String { hexToBytes() }` — when you touch that file, move it to `Extensions/String+Hex.swift` as part of the same change only if the task allows).
- **Models** → `State/Models/` or next to the feature if feature-private. One type per file.
- **Native (Objective-C / C) code** → `Bloom/Native/` (§10). Nothing else goes there.
- **Tests** → `BloomTests/`, `BloomUITests/`, `BloomPerformanceTests/` at the repository root (§7).
- **Do not hand-edit `project.pbxproj` to add files.** The synchronized group picks them up. Edit `project.pbxproj` only for build settings, targets or packages, and only when the task requires it.

---

## 5. Code style

### 5.1 Swift

- Swift API Design Guidelines apply. Types `UpperCamelCase`, everything else `lowerCamelCase`. No abbreviations except well-known ones (`id`, `URL`, `UI`).
- Four-space indentation, no tabs. Max line length 120. One blank line between members. No trailing whitespace.
- Prefer `struct`/`enum` over `class`. Use `final class` unless you need subclassing. Mark everything `private`/`fileprivate` by default; widen only when needed.
- Prefer `let` over `var`. Prefer early `guard` exits over nested `if`. No force unwrap (`!`), no `try!`, no `as!` outside tests and previews. No `fatalError` for recoverable situations.
- No magic numbers or colors in views. Use `Theme.spacing`, `Theme.radius`, `Theme.borderWidth`, `Theme.colors` (existing). If a needed token is missing, add it to `Core/Theme.swift` rather than hardcoding. Keep the existing `Theme` type shape; do not rename its nested types.
- Strings shown to users go through the String Catalog (`LOCALIZATION_PREFERS_STRING_CATALOGS = YES`). No hardcoded user-facing literals in new code.
- No commented-out code. No `TODO` without an owner/context line. Remove debug leftovers (e.g. the `// test test test (delete later)` block in `BloomApp.swift`) only when the task covers it.
- No `print`. Use `os.Logger` (§8.6). Currently 15 `print(` calls exist; do not add more, and replace those you touch.
- New files use the standard Xcode header with the file name and project name only (`//  FileName.swift` / `//  Bloom`). Do not invent an author name or date.
- Imports: only what the file uses; `import SwiftUI` already re-exports Foundation-level types used by views, do not add redundant imports.

### 5.2 Size and structure limits (hard rules)

| Unit | Soft limit | Hard limit | Action when exceeded |
|---|---|---|---|
| File | 150 lines | 250 lines | split into files |
| Type (struct/class/enum) | 150 lines | 200 lines | extract collaborators |
| Function / method | 25 lines | 40 lines | extract helpers |
| SwiftUI `body` | 30 lines | 50 lines | extract subviews |
| Function parameters | 4 | 6 | introduce a parameter struct |
| Nesting depth | 3 | 4 | early return / extract |

- **One primary type per file**, named after the file. Small private helper types used only by that type may share the file if the file stays under the limit.
- **SwiftUI decomposition:** extract a subview into its own file as soon as a part of `body` (a) has its own state, (b) is repeated, (c) has its own preview-worthy states, or (d) pushes `body` over the soft limit. Pass the smallest inputs possible (values or `Binding`s), not whole stores — this also limits invalidation (§9.3).
- **Existing violations:** `State/Models/BloomManagerModels.swift` (361), `State/BloomManager.swift` (340), `Components/UIKitContextMenu.swift` (232 — soft limit exceeded). Do **not** split them as a side effect of an unrelated task. When a task touches one of them substantially, split it as part of that task and say so, or propose the split separately.

### 5.3 Concurrency

- **[Fact]** The module's default actor isolation is `MainActor`. Everything is main-actor-isolated unless marked otherwise.
- **[Rule]** Anything that does non-trivial work (parsing, crypto, audio sample processing, I/O, large diffing) must be explicitly moved off the main actor: `nonisolated` functions, a dedicated `actor`, or a detached/`@concurrent` function. Never block the main thread. Hand results back to `@MainActor` as small value types.
- Use `async/await` and `AsyncStream` for new code. Do not add new `DispatchQueue` usage in Swift unless interoperating with a callback API; wrap such APIs once, in one place.
- Types crossing isolation boundaries must be `Sendable` (value types preferred). Do not use `@unchecked Sendable` without a written justification in a comment and a TSan run.
- Cancel tasks you start (`Task` stored and cancelled in `deinit`/`onDisappear`, or use `.task {}`, which cancels automatically).
- Do not raise `SWIFT_VERSION` to 6 or change isolation defaults unless asked. If asked, do it in a separate change and fix all resulting diagnostics.

### 5.4 Tooling files to add (when asked to set up tooling)

`.swiftlint.yml` (starting point; adjust only with maintainer approval):

```yaml
included: [Bloom, BloomTests, BloomUITests, BloomPerformanceTests]
excluded: [build, DerivedData]
line_length: { warning: 120, error: 160 }
file_length: { warning: 150, error: 250 }
type_body_length: { warning: 150, error: 200 }
function_body_length: { warning: 25, error: 40 }
function_parameter_count: { warning: 4, error: 6 }
nesting: { type_level: 2 }
force_cast: error
force_try: error
force_unwrapping: error
opt_in_rules: [empty_count, explicit_init, first_where, sorted_imports, unused_import, vertical_whitespace_closing_braces, overridden_super_call, discouraged_optional_boolean]
custom_rules:
  no_print:
    name: "No print"
    regex: '\bprint\('
    message: "Use os.Logger instead of print."
    severity: error
```

`.swiftformat`:

```
--swiftversion 5.0
--indent 4
--maxwidth 120
--wraparguments before-first
--wrapcollections before-first
--stripunusedargs closure-only
--disable redundantSelf
```

`Scripts/check-file-size.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
LIMIT=250
fail=0
while IFS= read -r f; do
  n=$(wc -l < "$f")
  if [ "$n" -gt "$LIMIT" ]; then echo "TOO LONG ($n > $LIMIT): $f"; fail=1; fi
done < <(find Bloom -type f \( -name '*.swift' -o -name '*.m' -o -name '*.h' \))
exit $fail
```

Existing files over the limit will make this script fail until they are split; mark them in an allowlist file (`Scripts/file-size-allowlist.txt`) rather than weakening the limit.

---

## 6. SwiftUI and iOS 26 guidelines

- **Native first.** If the platform already provides a control, container or modifier for the job (`TabView` and its tabs, `NavigationStack` toolbars, `.searchable`, `ContentUnavailableView`, `.sheet`, `.buttonStyle(.glass)`, `.page` tab style, standard menus), use it with its own configuration. Write a custom implementation only when the current prompt explicitly asks for one, or when the native control cannot meet a measured requirement from §9 — and say in the commit which of the two applies. Do not rebuild a system control "to match a mockup" with hand-rolled views.
- **Icons come from the asset catalog.** `Bloom/Assets.xcassets` holds the only icons the app uses (`bell`, `chat.bubbles`, `chevron.bottom`, `chevron.left`, `chevron.right`, `chevron.top`, `cloud`, `gear`, `key`, `logo`, `magnifyingglass`, `saved.flag`, `square.and.pencil`, `x.mark`). Use `Image("<name>")` with `.renderingMode(.template)` and tint it. Do not draw new SF Symbols where one of these fits; an SF Symbol is allowed only when the catalog has no suitable icon (for example `microphone.fill`, `arrow.up`, `trash`), and a new icon must be added to the catalog as an SVG imageset rather than pasted as a symbol name.
- Use iOS 26 APIs directly. Liquid Glass: prefer the system's native glass APIs over custom blur stacks; verify symbol names with §3.4 before use.
- **State:** `@Observable` for models, `@State` for view-owned state, `@Bindable` for bindings into observables, `@Environment` for shared app state. Do not introduce `ObservableObject`/`@Published`/Combine for new code.
- Keep observable models granular: a property that changes at high frequency (scroll offset, audio level, keyboard height) must not live on a model that large parts of the UI read. Put it in a small dedicated model read only by the view that needs it.
- **Navigation:** go through `Router` / `Route` / `ModalRoute`. Do not introduce a second navigation mechanism. Add routes by extending `Route`/`ModalRoute` and handling them in one place.
- **Previews:** every new view gets a `#Preview` with realistic data, both color schemes where colors matter.
- **Accessibility:** every interactive element has an accessibility label; support Dynamic Type; respect Reduce Motion (`accessibilityReduceMotion`) for custom transitions; check contrast for `Theme.colors` additions.
- **iPad:** the target supports iPad. New screens must not break at iPad sizes and in multitasking widths; do not assume phone-width constants.
- **Animations:** prefer animating properties that stay on the render/compositor path (opacity, offset, scale, rotation) over properties that force a layout pass each frame (frame size, intrinsic content). If you must animate size, fix the layout size and clip/mask instead, and prove the gain with §9.
- **Chat list/scroll:** the chat screen uses scroll-related tricks; do not change scroll architecture without a measurement (hitches, §9.2) before and after.

---

## 7. Testing

**[Fact]** There are currently no tests. Any task that adds or changes logic must add tests, which requires creating the targets below the first time. Creating a test target means editing `project.pbxproj` (targets are not covered by the synchronized-group shortcut); do it once, in its own change, and keep the diff minimal.

### 7.1 Required targets

| Target | Framework | Purpose |
|---|---|---|
| `BloomTests` | Swift Testing (`import Testing`) | unit and logic tests, security tests that need no UI |
| `BloomUITests` | XCTest / XCUIAutomation | critical flows (auth, send message, navigation) |
| `BloomPerformanceTests` | XCTest `measure` + metrics | speed regression tests (§9), device-only |

Also create a shared test plan `Bloom.xctestplan` with the three targets as separate configurations (so performance tests can be excluded from the default run), and enable code coverage for the `Bloom` target.

### 7.2 Rules

- Unit tests must be deterministic and fast (< 100 ms each). No real network, no real Keychain items from the production service name, no real clock/random: inject dependencies behind small protocols.
- Test names state behavior: `rejectsMnemonicWithInvalidChecksum`, not `test1`.
- Every bug fix ships with a regression test that fails before the fix.
- Cover: `Router` (push/pop/modal/pending-route), mnemonic validation and gating, models decoding (`BloomManagerModels`), message store logic, audio level processing, `Theme`/color parsing (`UIColor+Hex`), string helpers.
- Code that talks to `BloomKit` goes behind a protocol so it can be faked in tests. Do not call the real client from tests.
- UI tests use accessibility identifiers, never display text. Add `.accessibilityIdentifier` to elements you test.
- Test coverage target for new/changed non-UI logic: ≥ 80 %. Do not write tests that only assert implementation details to hit the number.

---

## 8. Security

Bloom is a messenger that handles a 12-word mnemonic (seed phrase) and local credentials. Treat every item below as a requirement, not advice.

### 8.1 Secrets and key material

- **Never** log, print, serialize into analytics, put into crash text, or copy to the general pasteboard: the mnemonic, derived keys, tokens, private keys, decrypted message bodies.
- Keep secrets in memory for the shortest possible time. Prefer `Data`/`[UInt8]` buffers that can be overwritten over `String` for key material; overwrite buffers when finished. Do not store secrets in `@Observable` models that views read, in `UserDefaults`, in files, in `NSUserActivity`, or in state restoration.
- Mnemonic input views: disable autocorrect, spell-checking, smart punctuation and predictive text (`.autocorrectionDisabled()`, `.textInputAutocapitalization(.never)`, `textContentType` unset, `keyboardType(.asciiCapable)`); clear fields on disappear and on moving to the background.
- Hide sensitive screens in the app switcher snapshot (blur/cover on `scenePhase != .active`). Consider `UITextField.isSecureTextEntry` behavior for screenshot masking; verify on a device before claiming it works.

### 8.2 Keychain

- **[Fact]** `Helpers/KeychainHelper.swift` stores values with `kSecClassGenericPassword`, and does **not** set `kSecAttrAccessible`; it also prints OSStatus values and returns no error to callers. Treat this as a known weakness.
- **[Rule]** Any new or modified Keychain write must:
  - set `kSecAttrAccessible` explicitly — default to `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; use `AfterFirstUnlockThisDeviceOnly` only if background access is a documented requirement;
  - never use `kSecAttrSynchronizable` (no iCloud Keychain sync) unless the maintainer explicitly approves;
  - use `SecAccessControl` with `.biometryCurrentSet` (or `.userPresence`) for the most sensitive items when biometric gating is introduced;
  - report errors (typed `throws`) instead of swallowing or printing them;
  - use `SecItemUpdate` or add-or-update logic rather than delete-then-add where atomicity matters;
  - use a distinct service name for tests.
- Do not change the Keychain service/account naming of existing items without a migration plan; changing it silently logs users out or orphans secrets.

### 8.3 Biometrics

- **[Fact]** The README promises a FaceID gate; the code on `main` does not implement one. Do not claim the app is biometrically protected in code, comments or docs unless it is.
- When implementing: use `LocalAuthentication` (`LAContext`), add `NSFaceIDUsageDescription` via `INFOPLIST_KEY_NSFaceIDUsageDescription` in build settings, tie secret access to `SecAccessControl` (not to a boolean the app flips), handle `LAError` cases (cancel, lockout, not enrolled, passcode fallback policy) explicitly, and re-lock on background/foreground transitions.
- A bypassable boolean such as `isUnlocked` stored in a normal property is not a security boundary; the real boundary is the Keychain access control.

### 8.4 Networking and data in transit

- ATS stays on. Never add `NSAllowsArbitraryLoads` or per-domain exceptions without maintainer approval.
- Validate and bound all external input (JSON sizes, string lengths, counts) before decoding or storing. Decode with strict models; unknown required fields must fail safely.
- If certificate pinning is added, do it centrally (one place), with a documented rotation plan.
- Anything that goes through `BloomKit` is a trust boundary: do not assume the callback data (`chatsJSON`, `userJSON`) is well-formed. Existing code swallows decode errors (`catch {}` in `UserObserver`); do not copy that pattern. Handle and log (privately) decode failures.

### 8.5 Storage and privacy

- Files that hold user data use `FileProtectionType.complete` (or `completeUnlessOpen` if background writes are required) and are excluded from backups when they contain secrets (`isExcludedFromBackup`).
- Audio recordings (`AudioRecorderManager`): write to a protected temporary location, delete after send/cancel, never leave them in shared containers.
- Do not add third-party SDKs (analytics, crash reporters, ads) without maintainer approval. Every new SPM dependency requires: license check (project is GPLv3), maintenance status, a pinned version range, and a note in the PR description about what data it can access.
- Pasteboard: never write secrets to `UIPasteboard.general`. If copy is a product requirement, use `UIPasteboard.general.setItems(_, options: [.localOnly: true, .expirationDate: …])` and tell the maintainer.

### 8.6 Logging

Use `os.Logger` with explicit privacy:

```swift
import OSLog

extension Logger {
    static let auth = Logger(subsystem: "pw.ephmrl.bloom", category: "auth")
}

Logger.auth.error("keychain write failed: \(status, privacy: .public)")
Logger.auth.debug("user id: \(userID, privacy: .private)")
```

Interpolated values are `.private` unless there is a reason (and it is not user data). Secrets are never interpolated at all.

### 8.7 Build and supply chain

- Keep `ENABLE_USER_SCRIPT_SANDBOXING = YES`. Do not add Run Script phases that fetch from the network.
- Commit `Package.resolved` for the Xcode project (it lives under `Bloom.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`, currently ignored via `*.xcodeproj/project.xcworkspace/` in `.gitignore`). If you propose changing the ignore rule, explain why: reproducible dependency versions are a security control.
- Never commit signing assets, provisioning profiles, `.env` files, API keys or the mnemonic of any real account. If you find one in history or in the tree, stop and report it; do not try to "clean" git history yourself.
- Debug-only code (test credentials, verbose logging) must be wrapped in `#if DEBUG`. Remember the scheme's Run action uses Release: debug-only code will not execute there.

### 8.8 Security tests (required for security-relevant changes)

Add in `BloomTests` (Swift Testing), using a test-only Keychain service name:

1. **Keychain accessibility:** after `save`, query with `kSecReturnAttributes` and assert `kSecAttrAccessible == kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (or the documented value) and `kSecAttrSynchronizable` is false/absent.
2. **Keychain round trip + overwrite + delete:** value is returned, replaced atomically, and gone after delete; failure paths return errors rather than silently succeeding.
3. **No secret in logs:** a test that runs the mnemonic flow with a custom `Logger`/log capture, or a static check (below), asserting the mnemonic words never reach logging calls.
4. **Mnemonic handling:** invalid checksum rejected; wrong word count rejected; whitespace/case normalization; buffer cleared after use (assert on the buffer type you introduce).
5. **Decoding hostile input:** oversized, truncated, wrongly typed and extra-field JSON for every model decoded from `BloomKit` callbacks must not crash and must not partially mutate state.
6. **Biometric gate (when implemented):** secret read fails without successful authentication (use an injectable `LAContext`-like protocol); re-lock after backgrounding.
7. **ATS/Info.plist assertions:** a test that loads the built app's `Info.plist` and asserts no `NSAllowsArbitraryLoads`, and that required usage-description keys exist for the capabilities used (microphone, and FaceID once added).
8. **UI test:** sensitive screen is covered in the app-switcher snapshot path (verify through `scenePhase` handling at the unit level; do not claim a UI-test guarantee you cannot verify).

`Scripts/security-audit.sh` (repo-level static check; extend as needed):

```bash
#!/usr/bin/env bash
set -uo pipefail
fail=0
check() { # description, pattern, paths...
  local desc="$1" pat="$2"; shift 2
  if grep -rnE --include='*.swift' --include='*.m' --include='*.h' "$pat" "$@" 2>/dev/null; then
    echo "SECURITY CHECK FAILED: $desc"; fail=1
  fi
}
check "print() in app code"                    '\bprint\('                          Bloom
check "NSLog in app code"                      '\bNSLog\('                          Bloom
check "arbitrary loads / ATS exceptions"       'NSAllowsArbitraryLoads|NSExceptionDomains' Bloom Bloom.xcodeproj
check "iCloud-synced keychain items"           'kSecAttrSynchronizable.*(true|kCFBooleanTrue)' Bloom
check "keychain add without accessibility"     'SecItemAdd' Bloom   # review manually: every hit must set kSecAttrAccessible
check "force try / force cast in app code"     'try!|as!'                           Bloom
check "secrets-looking literals"               '(api[_-]?key|secret|token|password)\s*[:=]\s*"[^"]+"' Bloom
exit $fail
```

Note: the `SecItemAdd` line intentionally flags every call site for manual review; refine it into an exact check once `KeychainHelper` is fixed.

---

## 9. Performance

Goal (from the project's own positioning): smooth 60/120 Hz UI, instant response. "Fast" is defined by numbers below, measured on a physical device.

### 9.1 Budgets (project defaults — maintainer may change them)

| Metric | Budget |
|---|---|
| Frame time on ProMotion devices | ≤ 8.3 ms (120 Hz); never > 16.6 ms in steady state |
| Hitch time ratio during scroll / transitions | < 5 ms/s (Apple's "Good" range) |
| Cold launch to first interactive frame | measure and record a baseline; do not regress by > 10 % |
| Main-thread hang | none ≥ 250 ms |
| Memory growth during a 60 s scripted chat scroll | no unbounded growth; no leaks |
| Chat message send → row visible | measure and record a baseline; do not regress by > 10 % |

If no baseline exists yet, the first performance task is to record one (§9.4) and commit it.

### 9.2 What to run

- **Instruments (on device, Release build, no debugger attached):** SwiftUI instrument (body counts, update causes), Time Profiler, Hangs, Hitches, Animation Hitches, Allocations, Leaks, Core Animation. Record before and after every performance-motivated change.
- **XCTest metrics** in `BloomPerformanceTests`:
  - `XCTClockMetric`, `XCTCPUMetric`, `XCTMemoryMetric`, `XCTStorageMetric`;
  - `XCTHitchMetric` (app-level scrolling/animation hitches) — scripted via XCUITest scrolling and transitions;
  - `XCTOSSignpostMetric` around custom intervals (add `OSSignposter` intervals in code for: launch, chat open, message send, waveform render, bottom sheet present/dismiss);
  - `XCTApplicationLaunchMetric` for launch time.
- **MetricKit** subscriber (optional, Release only) for field data: hang and launch diagnostics, no personal data.

Example performance test skeleton:

```swift
import XCTest

final class ChatScrollPerformanceTests: XCTestCase {
    func testChatScrollHitches() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestingSeedChat", "1"]
        let options = XCTMeasureOptions(); options.iterationCount = 5
        measure(metrics: [XCTHitchMetric(application: app), XCTCPUMetric(application: app), XCTMemoryMetric(application: app)],
                options: options) {
            app.launch()
            app.collectionViews.firstMatch.swipeUp(velocity: .fast)
            app.collectionViews.firstMatch.swipeDown(velocity: .fast)
        }
    }
}
```

(Verify the element query for the actual chat container and add the `-UITestingSeedChat` launch-argument handling behind `#if DEBUG` before using this.)

### 9.3 SwiftUI performance rules

- No work in `body`: no sorting, filtering, formatting, decoding or allocation of formatters. Precompute in the model or cache.
- Give `ForEach` stable identity (`Identifiable` with stable `id`, never `\.self` on mutable values or array indices when order changes).
- Use `LazyVStack`/`LazyHStack`/`List` for long collections. Do not wrap large collections in `VStack`.
- Avoid `AnyView`. Prefer `@ViewBuilder`, generics and `Group`.
- Narrow dependencies: pass values, not the whole store. Split a view so that a fast-changing property only invalidates the small view that shows it.
- Make leaf views `Equatable` (and use `.equatable()`) only when Instruments shows redundant body evaluations; otherwise leave them alone.
- Avoid `GeometryReader` on hot paths; prefer `onGeometryChange`, layout protocols, or `containerRelativeFrame`, and verify with the SwiftUI instrument.
- Use `Canvas`, `drawingGroup()`, or Metal for heavy custom drawing (waveforms, gradients, shaders), and measure with the Core Animation / Metal System Trace tools.
- Do not animate layout-affecting properties every frame (see §6). Do not use `DispatchQueue.main.async` to "fix" ordering; fix the state flow.
- Images: decode and downsample off the main thread; reuse `UIImage`/`CGImage` caches with explicit cost limits and memory-warning eviction.

### 9.4 Recording baselines

Store baselines in `BloomPerformanceTests/Baselines/` (Xcode baselines in the `.xcresult`/`.xcbaseline` format for the target device model) and note device model + OS version + Xcode version + configuration in the PR/commit text. A performance PR without before/after numbers will be rejected.

---

## 10. UIKit and Objective-C policy

Principle: **Swift + SwiftUI by default; UIKit when SwiftUI cannot meet the budget or lacks the API; Objective-C only for a measured hot path.** Do not rewrite working code in another language for style reasons.

### 10.1 Decision ladder

1. Can the problem be fixed inside SwiftUI (state granularity, identity, `Canvas`, `drawingGroup`, compositor-only animation)? → Do that first. Measure.
2. Still over budget, or SwiftUI has no public API for the behavior? → Use **UIKit in Swift** via `UIViewRepresentable` / `UIViewControllerRepresentable`. Precedent in this repo: `Components/UIKitContextMenu.swift`. Typical wins: per-frame custom animation driven by `CADisplayLink`/`CAMetalLayer`, complex gesture arbitration, text input with fine control, frame-accurate keyboard tracking, large scrolling lists with cell reuse (`UICollectionView` + diffable data source + `UIHostingConfiguration` only if it measures better).
3. Still over budget in a **CPU-bound inner loop** that Swift (`-O`, WMO, unsafe buffers, `@inline`, avoiding existentials/generics/ARC traffic) cannot fix? → Write that loop in **Objective-C/C** behind a minimal interface.

### 10.2 Proof requirement

An Objective-C or UIKit replacement is accepted only with:

- a baseline measurement of the current implementation (§9) on a physical device, Release configuration;
- the same measurement for the new implementation;
- an improvement of at least **15 % on the target metric or ≥ 1 ms per frame at p95** (project default; maintainer may change) — otherwise keep the Swift version;
- the measurement method committed as a performance test, so regressions are caught later.

State the result honestly. Swift in Release mode is often equal to Objective-C for numeric code; the gain, when it exists, usually comes from removing allocations, ARC retain/release traffic, dynamic dispatch, or bounds checks. Say which one the measurement shows. If you did not measure, you do not know.

### 10.3 Good candidates (verify each by measurement, none is assumed)

- audio sample/waveform processing (`AudioRecorderManager`, `ChatFooterWaveformView`): tight loops over `Float` buffers;
- hex/bytes conversions and other per-message string-to-bytes work (e.g. `hexToBytes()` is character-by-character with `String` appends today);
- hash/diff/search over large message arrays;
- hot `CALayer`/`CAShapeLayer` updates in custom drawing;
- keyboard/gesture-driven views that must update every display frame without SwiftUI invalidation.

### 10.4 Objective-C setup (first-time, one change, minimal diff)

1. Create `Bloom/Native/` and `Bloom/Native/Bloom-Bridging-Header.h`.
2. Set `SWIFT_OBJC_BRIDGING_HEADER = Bloom/Native/Bloom-Bridging-Header.h` on the `Bloom` target (Debug and Release). `CLANG_ENABLE_MODULES = YES` is already set.
3. Add `.h`/`.m` files in `Bloom/Native/`; the synchronized group compiles them automatically. Import only the headers Swift needs in the bridging header.
4. Add Objective-C tests in `BloomTests` through the same bridging header, or in a Swift test calling the Swift-facing API.

### 10.5 Objective-C rules

- Class prefix `BLM` (e.g. `BLMWaveformProcessor`). Categories on system classes must use a prefixed method name.
- Every header: `NS_ASSUME_NONNULL_BEGIN` / `NS_ASSUME_NONNULL_END`; explicit `nullable` where needed; lightweight generics on collections (`NSArray<NSNumber *> *`); `NS_SWIFT_NAME` for clean Swift names; `NS_SWIFT_NONISOLATED`/`NS_SWIFT_SENDABLE` or documented thread-safety on every class.
- ARC only. No manual retain/release. Mark weak delegates `weak`. Use `copy` for `NSString`/`NSArray`/`NSDictionary` properties.
- Keep the public surface minimal: pass plain buffers/value types (`const float *`, `NSData`), not Swift-bridged objects. Do no allocation per call in the hot path (reuse buffers).
- No raw `malloc` without matching `free` and a clear owner; prefer `NSMutableData`/stack buffers; always check lengths before pointer arithmetic (these files are in the security perimeter — see §8; run ASan + UBSan on every change).
- No logging of user data. Use `os_log` with `%{private}`.
- No Objective-C in views or business logic. Native code is leaf-level computation or low-level UIKit/CoreAnimation plumbing.
- Compile Objective-C with the project defaults plus `-Wall -Wextra` treated as errors for files in `Bloom/Native/` (`GCC_TREAT_WARNINGS_AS_ERRORS` scoped to this folder via per-file flags if a global switch is too strict).

### 10.6 UIKit (Swift) rules

- Wrapper views expose a small SwiftUI-facing API (value inputs + closures); all UIKit state lives in the wrapper's `Coordinator` or the UIKit view.
- `updateUIView` must be cheap and idempotent: compare incoming values with current state and skip redundant work.
- Drive per-frame work with `CADisplayLink` configured via `preferredFrameRateRange`; invalidate it on `dismantleUIView`/`deinit`. Never leave a display link running when the view is off screen.
- Break retain cycles explicitly (`[weak self]`; `CADisplayLink` holds its target strongly — use a weak proxy).
- Respect the main-thread checker; never touch UIKit off the main actor.

---

## 11. Dependencies

- **[Fact]** Current: `Bip39.swift`, `BlurUIKit`/`BlurSwiftUI`, `swift-collections` (`DequeModule`), plus the binary `BloomKit` (not in repo).
- Prefer the platform SDK over a dependency. Add a package only with maintainer approval, with a version range (`upToNextMajor`), license compatible with GPLv3, and a short rationale.
- Do not vendor or fork a dependency to patch it without approval.
- Do not touch `BloomKit` interfaces (generated Go/gomobile-style API — an inference from naming, not verified) from this repository; if an interface is missing or wrong, report it.

---

## 12. Git and change hygiene

- Branch from `main`. One logical change per commit/PR.
- A PR description states: what changed, why, how it was verified (commands from §3 and their results), what was not verified, and — for performance or security changes — the numbers/tests from §8–§9.
- Do not commit: `DerivedData/`, `build/`, `*.xcuserstate`, `xcuserdata/`, `*.xcresult`, signing material, `BloomKit.xcframework`.
- Do not force-push `main`. Do not rewrite shared history.
- Do not change `DEVELOPMENT_TEAM`, bundle ID, deployment target, signing style or the scheme's configuration without being asked.

### 12.1 Agents may commit and push

An agent working in this repository **may create commits and push them** to the
current branch (including `main`) without asking first, provided that:

- the change builds (§3.1) and every command the agent ran passed; failures are
  reported instead of hidden;
- the commit contains one logical change, and unrelated edits are left out;
- no secret, signing asset, `BloomKit.xcframework`, build output or local
  tooling config (§8.7, §12) is staged;
- the agent reports the commit hash and what was pushed in its final message.

Never `git push --force`, never rewrite pushed history, never `git reset --hard`
or `git checkout --` over uncommitted work that the agent did not create.
Ask before pushing to a branch that is not the current one.

### 12.2 Commit message format

Derived from the existing history: single-line subjects, imperative mood, no
Conventional Commits prefixes, no issue numbers.

**Subject**

- English, imperative mood, capitalized first word: `Add`, `Show`, `Load`,
  `Fix`, `Drop`, `Replace`, `Start`, `Move`, `Cache`, `Restore`, `Render`,
  `Search`, `Store`, `Pin`, `Remove`, `Split`, `Align`.
- Describe the behaviour the commit introduces, not the files it touches:
  `Show loading, empty and error states for chats`, not `update ChatListView`.
- Maximum 72 characters, no trailing period, no emoji, no `fix:`/`feat:`/`chore:`
  prefix, no ticket numbers (they belong in the body if they matter).
- Sentence case: capitalize only the first word and proper nouns
  (`Pin BlurUIKit to 1.7.0 and link BloomKit framework`).

**Body** (optional, one of the rare cases in this history)

Add a blank line after the subject, then wrap at 72 columns. Use it only when
the subject cannot carry the information: the reason behind a non-obvious
change, verification commands, before/after measurements, or parts that were
not verified. Bullets start with `-`.

```
Move audio recording off the main actor and cap level updates

Recording callbacks ran on the main thread and pushed a sample per
callback, which stuttered the chat footer. Capture now runs in an actor
and publishes at most 55 samples per recording.

Verified: Debug build on iPhone 13 Pro, voice note start/stop, waveform.
Not verified: interruption handling during a phone call.
```

**Never** write commit messages that only restate the diff (`update files`,
`fixes`, `WIP` on the final commit), and never commit with an empty message.

---

## 13. Definition of done (checklist)

Before saying a task is complete, confirm each applicable item and state which you could not check:

- [ ] Builds in Debug and Release with zero new warnings (§3.1); strict-concurrency build has no new diagnostics for touched code.
- [ ] No API used that was not verified for iOS 26 (§3.4); no availability checks for ≤ 26.0.
- [ ] New/changed files respect §5.2 size limits; each new type is in its own file; subviews are extracted.
- [ ] No `print`, no force unwraps/casts, no hardcoded colors/spacings/user-facing strings.
- [ ] Unit tests added/updated; all tests pass; regression test for any bug fix (§7).
- [ ] Security: §8 reviewed; security tests added/updated if secrets, storage, networking, auth or input parsing changed; `Scripts/security-audit.sh` clean (once it exists).
- [ ] Performance: if the change touches scrolling, animation, launch, chat rendering or audio — before/after numbers on a physical device (§9). If it replaces Swift/SwiftUI with UIKit/Objective-C — the proof in §10.2.
- [ ] Previews added for new views; accessibility labels and Dynamic Type checked.
- [ ] Final report lists: files changed, commands run with results, assumptions, unverified items, and any discrepancy found (§1.2).

---

## 14. When to stop and ask the maintainer

Stop and ask (do not guess) when:

- the change needs `BloomKit` and the framework is unavailable or its API is unclear;
- a task requires changing signing, bundle ID, deployment target, Swift language mode, actor-isolation defaults or Keychain item naming;
- a security rule here conflicts with the requested behavior;
- adding a dependency, an SDK, a network endpoint, an entitlement, or a new permission;
- no physical device is connected or reachable (never fall back to a simulator, §2 rule 9);
- a measurement is ambiguous (noisy results);
- the README and the code disagree about intended behavior (§1.2).

---

## 15. Skills (load automatically)

Installed with `npx skills add` (see the install command in the maintainer's notes). **Before starting a task, load the matching skill from this table and follow it.** Do not wait to be asked.

| Task touches | Load skill(s) |
|---|---|
| SwiftUI views, state, layout, navigation | `swiftui-expert-skill` |
| Animations, transitions, gestures | `swiftui-animation`, `swiftui-expert-skill` |
| Speed, hitches, slow scrolling, launch time | `swiftui-performance`, `ios-ettrace-performance`, `debugging-instruments`, `metrickit` |
| UIKit inside SwiftUI (replacing a view for speed, §10) | `swiftui-uikit-interop` |
| Liquid Glass | `swiftui-liquid-glass` |
| Keychain, biometrics, auth, mnemonic, storage (§8) | `swift-security`, `authentication` |
| Actors, `Sendable`, async/await (§5.3) | `swift-concurrency` |
| Writing tests (§7) | `swift-testing` |
| Lint / style (§5) | `swiftlint` |

How to load (opencode): call the `skill` tool with the exact skill ID from the available-skills list (for example `{"id": "swiftui-performance"}`). Loading is not automatic: you must call it yourself before starting, based on the table above.

Rules:
- **This file wins over any skill.** If a skill step conflicts with a rule here (for example, any step that uses the iOS Simulator, §2 rule 9), skip that step and use the physical device.
- If a skill listed above is not installed, say so in your report and continue with this file only. Do not invent the skill's contents.
- A skill never replaces measurement (§9) or the proof requirement for UIKit/Objective-C (§10.2).
