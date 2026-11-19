//
//  ChatMenuHaptics.swift
//  Bloom
//

import UIKit

/// Haptics for the context menu. Generators are created on demand and prepared before firing.
enum ChatMenuHaptics {
    static func lift() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.8)
    }

    static func select() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func action() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
