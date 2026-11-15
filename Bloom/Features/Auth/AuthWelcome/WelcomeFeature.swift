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
            id: "chats",
            title: "Private chats",
            subtitle: "Messages are encrypted before they leave your phone",
            icon: "chat.bubbles",
            hue: 0.58,
            saturation: 0.55,
            brightness: 0.95
        ),
        WelcomeFeature(
            id: "sync",
            title: "Always in sync",
            subtitle: "Pick up the conversation on any of your devices",
            icon: "cloud",
            hue: 0.09,
            saturation: 0.65,
            brightness: 1.0
        ),
        WelcomeFeature(
            id: "recovery",
            title: "Yours to recover",
            subtitle: "Twelve words are all you need to get your account back",
            icon: "key",
            hue: 0.35,
            saturation: 0.5,
            brightness: 0.9
        )
    ]
}
