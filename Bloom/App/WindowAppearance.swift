//
//  WindowAppearance.swift
//  Bloom
//

import SwiftUI
import UIKit

/// Cross-fades the window when the appearance mode changes. A window-level trait change keeps the
/// transition on the compositor: no snapshot of the hierarchy and no extra layout pass.
enum WindowAppearance {
    @MainActor
    static func apply(_ mode: AppearanceMode, animated: Bool, reduceMotion: Bool) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first else {
            return
        }

        let style = mode.userInterfaceStyle
        guard animated, !reduceMotion else {
            window.overrideUserInterfaceStyle = style
            return
        }

        UIView.transition(with: window, duration: 0.32, options: .transitionCrossDissolve) {
            window.overrideUserInterfaceStyle = style
        }
    }
}
