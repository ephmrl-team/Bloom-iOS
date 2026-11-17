# AGENTS.md — Bloom iOS

Rules for agents working here — hard rules unless marked "prefer". Deeper notes live in `docs/`:

## Where to look first

`docs/animations.md` (Liquid Glass, keyboard, composer) · `docs/navigation.md` (screens, routes, toolbars, blur)
`docs/security.md` (mnemonic, Keychain, logging) · `docs/device-workflow.md` (USB iPhone, screenshots, sheets)

## Project

- iOS 26.0+ iPhone/iPad messenger, SwiftUI only. Bundle `pw.ephmrl.bloom`, single target `Bloom`, scheme `Bloom`.
- Swift 5.0 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`: everything is main-actor unless marked
  otherwise. Move parsing, crypto, audio and I/O off it with `nonisolated`, an `actor` or `@concurrent`.
- State: `@Observable` injected with `.environment(...)`. Never add `ObservableObject`, `@Published` or Combine.
- Navigation goes through `Navigation/Router.swift` (`Route`, `ModalRoute`). No second navigation mechanism.
- `BloomKit.xcframework` is not in the repository but is required to build. Its API is a trust boundary:
  validate payloads and log decode failures instead of swallowing them.
- Sources sit in a file-system-synchronized group: new files under `Bloom/` are picked up automatically.
  Never edit `project.pbxproj` to add Swift files — only for build settings, targets or packages.
- macOS scripts live in `Scripts/` only, never in `Bloom/`; their artefacts go to `build/`.

## Code style

- One primary type per file, named after the file. Features in `Features/<Feature>/`, shared UI in
  `Components/`, extensions in `Extensions/<Type>+<Purpose>.swift`, models in `State/Models/`.
- Limits: file ≤ 250 lines (soft 150), type ≤ 200, function ≤ 40 (soft 25), `body` ≤ 50 (soft 30),
  parameters ≤ 6 (soft 4), nesting ≤ 4. Extract a subview or helper instead of growing a file.
- 4-space indent, ≤ 120 columns, no trailing whitespace. `private` by default, `let` over `var`,
  early `guard` exits, no commented-out code.
- No `print(`, no `NSLog(`: use `os.Logger` (`Extensions/Logger+Bloom.swift`). No `!`, `try!`, `as!`,
  `fatalError` outside tests and previews.
- Icons come from `Bloom/Assets.xcassets` as `Image("<name>").renderingMode(.template)`. Do not invent
  SF Symbol names; add an SVG imageset when the catalog has no suitable icon.
- Colors, spacing, radii, borders and toolbar title metrics come from `Theme` (`Bloom/Core/Theme.swift`).
  No literal colors or magic spacing in views — add a token when one is missing.
- Toolbar titles have one shape: 18 pt bold rounded text with a leading catalog icon at 23 pt and a 6 pt
  gap (`Theme.toolbarTitle`, reference `ChatListTitle`).
- User-facing strings go into `Bloom/Localizable.xcstrings` (en + ru). No hardcoded literals in new code.
- Keep `topVariableBlur()` on screens whose header or footer floats over scrolling content.

## Security

- Never log, print, sync or paste secrets: mnemonic, keys, tokens, message bodies.
- Keychain writes set `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, never `kSecAttrSynchronizable`,
  and return typed errors instead of swallowing them.
- ATS stays on. No new permissions, SDKs, endpoints or entitlements without asking first.
- Do not weaken Keychain or biometric handling, and do not claim protections the code does not implement.

## Scope and tests

- Touch only the files the task needs. No drive-by refactors, renames or reformatting.
- Do not write tests unless the task asks for them; when asked, use Swift Testing in `BloomTests/` and keep
  them deterministic. Every bug fix then ships with a regression test.
- Never change bundle ID, deployment target, signing, Swift version or actor-isolation defaults unless asked.

## Git

- **Never run `git commit` or `git push` without an explicit instruction from the maintainer in the current
  task.** Leave the work uncommitted; never `git push --force`, rewrite history or discard work you did not create.

## Autonomous pipeline — run it yourself on every task

1. Read the `docs/*.md` above, then the target files. Edit only what the task needs.
2. Run `./Scripts/verify.sh` (AGENTS.md length, file sizes, security audit, swiftformat, `swiftlint --strict`,
   Debug build, strict-concurrency build) and fix every failure until it exits 0.
3. The USB iPhone stays connected for the whole task: after `Bloom/` changes run `./Scripts/run_on_iphone.sh`
   (`--launch-arg -AppMode=mock` or `BLOOM_LAUNCH_ARGS`) and report install and launch; if it drops off, say so.
4. Changed UI, layout or animation → `./Scripts/visual_check.sh screen` (or `anim 4`), read the `vision` report,
   fix clear defects. Two iterations at most. If the model returns nothing or capture fails, say so and list
   exactly what to check on the phone.
5. Report changed files, the result of each command, what was not verified, whether `README.md` changed.

**No simulator, ever.** Builds use `-destination 'generic/platform=iOS'`; tests run on the connected phone and
only when the task asks for them.
