//
//  AppAccent.swift
//  Bloom
//

import SwiftUI

enum AppAccent: String, CaseIterable, Identifiable {
    case blue
    case orange
    case red
    case purple
    case green
    case cyan
    case pink
    case black

    static let storageKey = "appAccent"

    var id: String {
        rawValue
    }

    var title: LocalizedStringKey {
        switch self {
        case .blue: "Blue"
        case .orange: "Orange"
        case .red: "Red"
        case .purple: "Purple"
        case .green: "Green"
        case .cyan: "Cyan"
        case .pink: "Pink"
        case .black: "Black"
        }
    }

    var color: Color {
        switch self {
        case .blue: Theme.colors.blue
        case .orange: Theme.colors.accentOrange
        case .red: Theme.colors.accentRed
        case .purple: Theme.colors.accentPurple
        case .green: Theme.colors.accentGreen
        case .cyan: Theme.colors.accentCyan
        case .pink: Theme.colors.accentPink
        case .black: Theme.colors.text
        }
    }

    /// Text and icons drawn on the accent. The monochrome accent inverts with the theme.
    var contentColor: Color {
        self == .black ? Theme.colors.background : Theme.colors.white
    }

    /// The gooey bridge only makes sense between two neighbours in the swatch row.
    func isAdjacent(to other: AppAccent) -> Bool {
        guard let first = Self.allCases.firstIndex(of: self),
              let second = Self.allCases.firstIndex(of: other)
        else {
            return false
        }
        return abs(first - second) == 1
    }
}
