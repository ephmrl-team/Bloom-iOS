//
//  SettingsTint.swift
//  Bloom
//

import SwiftUI

/// Per-row palette, built the same way as `WelcomeFeature` so the badge reads as a pressed tile.
struct SettingsTint {
    let hue: Double
    let saturation: Double
    let brightness: Double

    var gradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: hue, saturation: saturation * 0.5, brightness: brightness),
                Color(hue: hue, saturation: saturation, brightness: brightness * 0.85),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var iconColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness * 0.7)
    }

    static let orange = SettingsTint(hue: 0.09, saturation: 0.65, brightness: 1.0)
    static let green = SettingsTint(hue: 0.35, saturation: 0.5, brightness: 0.9)
    static let pink = SettingsTint(hue: 0.97, saturation: 0.55, brightness: 1.0)
    static let purple = SettingsTint(hue: 0.75, saturation: 0.55, brightness: 1.0)
    static let cyan = SettingsTint(hue: 0.55, saturation: 0.55, brightness: 1.0)
    static let blue = SettingsTint(hue: 0.58, saturation: 0.6, brightness: 1.0)
    static let gray = SettingsTint(hue: 0, saturation: 0, brightness: 0.75)
}
