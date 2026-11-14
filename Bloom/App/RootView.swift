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

    var body: some View {
        ZStack {
            switch bloomManager.startup {
            case .starting:
                ProgressView()
            case .failed:
                StartupFailureView {
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
                .transition(
                    .opacity
                        .combined(with: .blur(radius: 10))
                )

        case .main:
            ContentView()
                .transition(
                    .opacity
                        .combined(with: .blur(radius: 10))
                )
        }
    }
}
