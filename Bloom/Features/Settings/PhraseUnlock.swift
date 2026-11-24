//
//  PhraseUnlock.swift
//  Bloom
//

import LocalAuthentication
import OSLog

/// Face ID (with the device passcode as a fallback) gates showing the phrase again.
enum PhraseUnlock {
    nonisolated static func request() async -> Bool {
        let context = LAContext()
        var error: NSError?
        // No biometrics or passcode on this device: never lock the owner out of their own phrase.
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return true
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "Show your recovery phrase")
            )
        } catch {
            Logger.bloom.error("phrase unlock failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
