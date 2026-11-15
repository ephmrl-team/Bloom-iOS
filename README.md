<div align="center">

  <img src="https://github.com/user-attachments/assets/e54561b6-0a13-4fbb-af9f-88e0ea252e42" alt="Bloom Logo" width="150"/>
  <br/>

  # Bloom

  **Secured as a bank · Simple as SMS · Fast as Formula 1**

  <p align="center">
    <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-26.0%2B-black?style=for-the-badge&logo=apple" alt="iOS 26+"/></a>
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.0-orange?style=for-the-badge&logo=swift" alt="Swift 5"/></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-green?style=for-the-badge" alt="License GPLv3"/></a>
  </p>

  <p align="center">
    An end-to-end encrypted iOS messenger written in Swift and SwiftUI.
  </p>
</div>

---

## What Bloom is

A native iPhone and iPad messenger. Accounts are identified by a 12-word
recovery phrase instead of a password; messages are decrypted on the device by
the backend client. The UI is plain SwiftUI with a small custom navigation
layer and the system Liquid Glass effects.

## Stack

| Area | What we use |
|---|---|
| UI | SwiftUI, Liquid Glass (`glassEffect`, `GlassEffectContainer`) |
| State | Swift Observation (`@Observable`), injected through `.environment` |
| Navigation | `NavigationPath` based `Router` (`Bloom/Navigation`) |
| Blur | `BlurUIKit` / `BlurSwiftUI` variable blur |
| Collections | `swift-collections` (`Deque` for message lists) |
| Mnemonic | `Bip39.swift` (BIP39 validation and entropy handling) |
| Backend | `BloomKit.xcframework` — a prebuilt client library, **not in this repository** |
| Storage | Keychain, device-only items |

Language mode is `SWIFT_VERSION = 5.0` with approachable concurrency and
`MainActor` as the default isolation. Deployment target is iOS 26.0.

## Getting started

### Requirements

- Xcode 26 or newer
- iOS 26 device (the project is developed on physical devices)

### Build

1. Clone the repository:
   ```bash
   git clone https://github.com/ephmrl-team/Bloom-iOS.git
   cd Bloom-iOS
   ```
2. Put `BloomKit.xcframework` in the repository root. The project links it and
   will not compile without it; the binary is distributed separately.
3. Open `Bloom.xcodeproj`, pick your team under *Signing & Capabilities*, and run.

Command line:

```bash
xcodebuild -project Bloom.xcodeproj -scheme Bloom \
  -destination 'generic/platform=iOS' -configuration Debug build

xcodebuild test -project Bloom.xcodeproj -scheme Bloom \
  -destination 'platform=iOS,id=<DEVICE ID>'
```

### App modes

The app picks its backend at launch (`Bloom/App/AppMode.swift`):

- **dev** — debug builds, mock scenarios only.
- **mock** — in-memory backend with fake users and chats, Debug only:
  `-AppMode=mock`, optionally `-MockScenario=empty|error|large`.
- **release** — production. The real `BloomKit` client is the only backend.

## Project layout

```
Bloom/
  App/          app entry point, root view, auth flow
  Navigation/   Router, routes, app state
  State/        BloomManager, MessagesStore, audio, API layer, models
  Core/         Theme tokens
  Components/   reusable views
  Features/     Auth, ChatList, Chat, NewMessage, Profile, Settings
BloomTests/     unit tests (Swift Testing)
BloomUITests/   UI tests (XCTest)
```

## Security status — read before trusting claims

- Messages and keys are handled by `BloomKit`; this repository contains the UI
  and the local credential handling.
- Keychain items are written with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
  and are not synced to iCloud.
- **There is no biometric lock yet.** No `LocalAuthentication` gate, no
  `NSFaceIDUsageDescription`. Do not describe the app as Face ID protected until
  it exists.
- Screens that show the recovery phrase are hidden from the app switcher.

## Contributing

Read [`AGENTS.md`](AGENTS.md) before changing code: it holds the build, style,
security, performance and commit rules for this repository.

## License

Bloom is released under the **GNU GPLv3** license. See [LICENSE](LICENSE).
You may use, study, share and modify the software as long as derivative work
stays open source.
