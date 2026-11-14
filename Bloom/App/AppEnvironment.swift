//
//  AppEnvironment.swift
//  Bloom
//

import Foundation

/// Composition root: builds the object graph for `AppMode.current`.
@MainActor
struct AppEnvironment {
    let bloomManager: BloomManager

    static func make() throws -> AppEnvironment {
        #if DEBUG
        if AppMode.current == .mock {
            return AppEnvironment(bloomManager: BloomManager(backend: MockAPI()))
        }
        #endif
        return AppEnvironment(bloomManager: BloomManager(backend: try BloomKitAPI()))
    }
}
