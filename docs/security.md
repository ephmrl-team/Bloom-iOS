# Security

Read this before touching the mnemonic, Keychain, logging, storage or anything that shows secret material.

## Secrets

- The mnemonic, derived keys, tokens, decrypted message bodies and the local database key never go into logs,
  analytics, crash text, `UserDefaults`, files or the general pasteboard.
- `KeychainHelper.shared.save/read/delete(service:account:)` is the only credential store. Every write sets
  `kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and never sets
  `kSecAttrSynchronizable` — no iCloud Keychain sync, no backup restoration of secrets.
- Writes use `SecItemUpdate` first and `SecItemAdd` only on `errSecItemNotFound`; failures throw
  `KeychainError.status(_:)` and are logged with the status only, never the value.
- Service names: `pw.bloomapp.auth` for the recovery key and `db_encryption_key`. Do not rename an existing
  service or account without a migration plan — it silently logs every user out.
- The database key is deliberately kept on logout: deleting it while the encrypted database is still on disk
  leaves the next launch unable to open it (`BloomKitAPI.clearCredentials()`).

## Screens with secret material

- The recovery phrase screens call `.hidesSensitiveContent()` (`Extensions/View+SensitiveContent.swift`),
  which covers the content when `scenePhase != .active` or the scene is being captured. Keep it on any new
  screen that renders a mnemonic, a key or a private message.
- Mnemonic inputs disable autocorrect, spell-checking, smart punctuation and predictive text, use
  `keyboardType(.asciiCapable)`, and clear their content when the view disappears.

## Logging

- Use `Logger.bloom` (`Extensions/Logger+Bloom.swift`) with explicit privacy:
  `Logger.bloom.error("keychain write failed: \(status, privacy: .public)")`. Interpolated user data is
  `.private`; secrets are never interpolated at all.
- No `print(`, no `NSLog(` anywhere — `Scripts/security-audit.sh` fails the build on both.

## Boundaries

- Everything that comes back from `BloomKit` (`chatsJSON`, `userJSON`, messages) is untrusted: decode with
  strict models, bound sizes, and log decode failures instead of `catch {}`.
- ATS stays on: no `NSAllowsArbitraryLoads`, no per-domain exceptions. No new permission, SDK, endpoint or
  entitlement without maintainer approval.
- Biometrics are not implemented. Do not describe the app as Face ID protected, and do not add a boolean
  "isUnlocked" flag as a substitute for `SecAccessControl` when one is added.
