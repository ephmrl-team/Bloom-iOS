//
//  View+SensitiveContent.swift
//  Bloom
//

import SwiftUI

extension View {
    /// Covers the content while the app is inactive or the screen is being captured.
    /// `paused` keeps the content visible while a system prompt (Face ID) makes the scene inactive.
    func hidesSensitiveContent(paused: Bool = false) -> some View {
        modifier(HiddenSensitiveContentModifier(paused: paused))
    }
}

private struct HiddenSensitiveContentModifier: ViewModifier {
    var paused = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isSceneCaptured) private var isSceneCaptured

    private var isHidden: Bool {
        isSceneCaptured || (!paused && scenePhase != .active)
    }

    func body(content: Content) -> some View {
        content.overlay {
            if isHidden {
                ZStack {
                    Color(.systemBackground)

                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundStyle(Theme.colors.secondaryText)
                }
                .ignoresSafeArea()
            }
        }
    }
}
