//
//  SettingsRoute.swift
//  Bloom
//

import Foundation

/// The Settings tab owns its own stack, so its destinations stay out of `Router.path`.
enum SettingsRoute: Hashable {
    case profile(id: String)
    case recoveryPhrase
    case encryptionKeys
    case appearance
    case storage
    case about
}
