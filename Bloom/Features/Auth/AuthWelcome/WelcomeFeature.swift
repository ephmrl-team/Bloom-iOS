//
//  WelcomeFeature.swift
//  Bloom
//

import SwiftUI

struct WelcomeFeature: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let hue: Double
    let saturation: Double
    let brightness: Double

    var gradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: hue, saturation: saturation * 0.5, brightness: brightness),
                Color(hue: hue, saturation: saturation, brightness: brightness * 0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// The icon sits a third darker than the bottom colour so it reads as pressed into the tile.
    var iconColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness * 0.7)
    }

    static let all: [WelcomeFeature] = [
        WelcomeFeature(
            id: "encryption",
            title: "Seamless encryption",
            subtitle: "Messages are encrypted on your device, so only you can read them",
            icon: "key",
            hue: 0.35,
            saturation: 0.5,
            brightness: 0.9
        ),
        WelcomeFeature(
            id: "conversations",
            title: "Easy conversations",
            subtitle: "Voice notes, quick replies and a clean interface",
            icon: "chat.bubbles",
            hue: 0.58,
            saturation: 0.55,
            brightness: 0.95
        ),
        WelcomeFeature(
            id: "handy",
            title: "Always with you",
            subtitle: "Open the same chats on every device you sign in to",
            icon: "cloud",
            hue: 0.09,
            saturation: 0.65,
            brightness: 1.0
        )
    ]
}
