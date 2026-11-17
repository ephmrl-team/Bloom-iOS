//
//  BloomApp.swift
//  Bloom
//

import OSLog
import SwiftUI

@main
struct BloomApp: App {
    @State private var appState = AppState()
    @State private var networkMonitor = NetworkMonitor()
    @State private var environment: AppEnvironment?
    @State private var startupError: String?

    init() {
        let result = Self.createEnvironment()
        _environment = State(initialValue: try? result.get())
        _startupError = State(initialValue: result.failureMessage)
    }

    var body: some Scene {
        WindowGroup {
            if let environment {
                RootView()
                    .environment(appState)
                    .environment(networkMonitor)
                    .environment(environment.bloomManager)
            } else {
                StartupFailureView(detail: startupError) {
                    let result = Self.createEnvironment()
                    environment = try? result.get()
                    startupError = result.failureMessage
                }
            }
        }
    }

    private static func createEnvironment() -> Result<AppEnvironment, Error> {
        do {
            return try .success(AppEnvironment.make())
        } catch {
            Logger.bloom.error("app failed to start: \(error, privacy: .public)")
            return .failure(error)
        }
    }
}

private extension Result {
    var failureMessage: String? {
        guard case let .failure(error) = self else { return nil }
        return error.localizedDescription
    }
}
