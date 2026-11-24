//
//  BloomKitAPI+RecoveryPhrase.swift
//  Bloom
//

import Bip39
import Foundation
import OSLog

extension BloomKitAPI {
    /// The stored key is either the mnemonic (login) or its hex entropy (registration).
    func recoveryPhrase() -> String? {
        guard let key = savedRecoveryKey() else { return nil }

        if key.contains(" ") {
            return key
        }

        let hex = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard hex.count.isMultiple(of: 2), hex.allSatisfy(\.isHexDigit) else {
            Logger.bloom.error("recovery key is not a hex string")
            return nil
        }

        do {
            let mnemonic = try Mnemonic(entropy: hex.hexToBytes())
            return mnemonic.mnemonic().joined(separator: " ")
        } catch {
            Logger.bloom.error("recovery phrase decode failed: \(error, privacy: .public)")
            return nil
        }
    }
}
