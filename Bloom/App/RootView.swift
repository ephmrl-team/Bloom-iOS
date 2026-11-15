//
//  RootView.swift
//  Bloom
//
//  Created by Аскольд on 14.08.2026.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(BloomManager.self) private var bloomManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var rootTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .blur(radius: 10))
    }

    var body: some View {
        ZStack {
            switch bloomManager.startup {
            case .starting:
                ProgressView()
            case .failed:
                StartupFailureView(detail: bloomManager.startupError) {
                    Task { await bloomManager.start() }
                }
            case .ready:
                root
            }
        }
        .onChange(of: bloomManager.hasRestoredSession, initial: true) { _, restored in
            if restored {
                appState.authenticate()
            }
        }
    }

    @ViewBuilder
    private var root: some View {
        switch appState.root {
        case .auth:
            AuthFlow()
                .transition(rootTransition)

        case .main:
            ContentView()
                .transition(rootTransition)
        }
    }
}
