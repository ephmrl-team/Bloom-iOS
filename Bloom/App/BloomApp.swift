//
//  BloomApp.swift
//  Bloom
//

import SwiftUI
import OSLog

@main
struct BloomApp: App {
    @State private var appState = AppState()
    @State private var environment: AppEnvironment? = BloomApp.start()

    var body: some Scene {
        WindowGroup {
            if let environment {
                RootView()
                    .environment(appState)
                    .environment(environment.bloomManager)
            } else {
                StartupFailureView {
                    environment = BloomApp.start()
                }
            }
        }
    }

    private static func start() -> AppEnvironment? {
        do {
            return try AppEnvironment.make()
        } catch {
            Logger.bloom.error("app failed to start: \(error, privacy: .public)")
            return nil
        }
    }
}
