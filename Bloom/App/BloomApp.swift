//
//  BloomApp.swift
//  Bloom
//

import SwiftUI

@main
struct BloomApp: App {
    @State private var appState = AppState()
    @State private var bloomManager: BloomManager

    init() {
        _bloomManager = State(initialValue: AppEnvironment.make().bloomManager)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(bloomManager)
        }
    }
}
