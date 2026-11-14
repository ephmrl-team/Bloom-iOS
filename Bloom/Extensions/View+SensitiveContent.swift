//
//  View+SensitiveContent.swift
//  Bloom
//

import SwiftUI

extension View {
    /// Covers the content while the app is inactive or the screen is being captured.
    func hidesSensitiveContent() -> some View {
        modifier(HiddenSensitiveContentModifier())
    }
}

private struct HiddenSensitiveContentModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isSceneCaptured) private var isSceneCaptured

    private var isHidden: Bool {
        scenePhase != .active || isSceneCaptured
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
