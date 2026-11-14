//
//  AppMode.swift
//  Bloom
//

import Foundation

/// Which backend the app talks to. Resolved once at launch.
enum AppMode: String {
    case dev
    case release
    #if DEBUG
    case mock
    #endif

    static let current: AppMode = resolve()

    private static func resolve() -> AppMode {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("-AppMode=") })?
            .split(separator: "=", maxSplits: 1)
            .last,
           let mode = AppMode(rawValue: String(raw)) {
            return mode
        }
        return .dev
        #else
        return .release
        #endif
    }

    /// MOCK must never be able to reach BloomKit or the network.
    var allowsRealAPI: Bool {
        #if DEBUG
        return self != .mock
        #else
        return true
        #endif
    }
}
