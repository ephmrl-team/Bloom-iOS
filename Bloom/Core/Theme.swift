//
//  Theme.swift
//  Bloom
//
//  Created by Аскольд on 11.08.2026.
//

import SwiftUI
import UIKit

enum Theme {
    enum spacing {
        static let xxs: CGFloat = 2
        static let micro: CGFloat = 6
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 28
        static let modal: CGFloat = 40
    }

    enum radius {
        static let xxs: CGFloat = 8
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 42
        static let composer: CGFloat = 22
        static let full: CGFloat = 999
    }

    enum borderWidth {
        static let md: CGFloat = 0.85
    }

    /// Toolbar titles: one shape for every screen (see AGENTS.md, "Toolbar titles").
    enum toolbarTitle {
        static let fontSize: CGFloat = 18
        static let iconSize: CGFloat = 23
        static let spacing: CGFloat = 6
    }

    enum colors {
        static let background = Color.dynamic(lightHex: "ffffff", darkHex: "000000")
        static let text = Color.dynamic(lightHex: "000000", darkHex: "ffffff")
        static let grayBackground = Color.dynamic(lightHex: "f1f1f4", darkHex: "000000ff")
        static let secondaryText = Color.dynamic(lightHex: "0000006b", darkHex: "ffffff6b")
        static let switcher = Color.dynamic(lightHex: "d7d7db", darkHex: "595959")
        static let pressable = Color.dynamic(lightHex: "d7d6dc", darkHex: "333333")
        static let sectionForeground = Color.dynamic(lightHex: "ffffff", darkHex: "1b1b1d")
        static let foreground = Color.dynamic(lightHex: "f1f1f4", darkHex: "1b1b1d")
        static let foregroundTransparent = Color.dynamic(lightHex: "0000001c", darkHex: "ffffff1c")
        static let indicator = Color.dynamic(lightHex: "0000001a", darkHex: "ffffff26")
        static let border = Color.dynamic(lightHex: "0000000d", darkHex: "ffffff17")
        static let shadow = Color.dynamic(light: Color.black.opacity(0.08), dark: Color.clear)

        static let white = Color(uiColor: UIColor(hex: "ffffff"))
        static let black = Color(uiColor: UIColor(hex: "000000"))
        static let primary = Color(uiColor: UIColor(hex: "42A1FF"))
        static let orange = Color(uiColor: UIColor(hex: "FF531B"))
        static let green = Color(uiColor: UIColor(hex: "1AFF7A"))
        static let pink = Color(uiColor: UIColor(hex: "FF1A45"))
        static let yellow = Color(uiColor: UIColor(hex: "FF901A"))
        static let cyan = Color(uiColor: UIColor(hex: "28A8E9"))
        static let purple = Color(uiColor: UIColor(hex: "A41AFF"))
        static let red = Color(uiColor: UIColor(hex: "EE362B"))
        static let gray = Color(uiColor: UIColor(hex: "8C8C8C"))

        static let whiteBackdrop = white.opacity(0.5)
        static let blackBackdrop = black.opacity(0.5)
        static let primaryBackdrop = primary.opacity(0.5)
        static let orangeBackdrop = orange.opacity(0.5)
        static let greenBackdrop = green.opacity(0.5)
        static let pinkBackdrop = pink.opacity(0.5)
        static let yellowBackdrop = yellow.opacity(0.5)
        static let cyanBackdrop = cyan.opacity(0.5)
        static let purpleBackdrop = purple.opacity(0.5)
        static let redBackdrop = red.opacity(0.5)
        static let grayBackdrop = gray.opacity(0.5)
        static let glassBackdrop = pressable.opacity(0.55)
    }
}

private extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    static func dynamic(lightHex: String, darkHex: String) -> Color {
        Color(uiColor: .dynamic(lightHex: lightHex, darkHex: darkHex))
    }
}
