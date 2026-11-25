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

    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage(AppAccent.storageKey) private var accentRaw = AppAccent.blue.rawValue

    private var accent: AppAccent {
        AppAccent(rawValue: accentRaw) ?? .blue
    }

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
        .accentColor(accent.color)
        .tint(accent.color)
        .onAppear {
            WindowAppearance.apply(
                AppearanceMode(rawValue: appearanceModeRaw) ?? .system,
                animated: false,
                reduceMotion: reduceMotion
            )
        }
        .onChange(of: appearanceModeRaw) { _, raw in
            WindowAppearance.apply(
                AppearanceMode(rawValue: raw) ?? .system,
                animated: true,
                reduceMotion: reduceMotion
            )
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
