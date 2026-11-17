//
//  UIColor+Hex.swift
//  Bloom
//
//  Created by Аскольд on 11.08.2026.
//

import SwiftUI

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let red, green, blue, alpha: CGFloat
        switch hex.count {
        case 3:
            red = CGFloat((int >> 8) * 17) / 255
            green = CGFloat((int >> 4 & 0xF) * 17) / 255
            blue = CGFloat((int & 0xF) * 17) / 255
            alpha = 1.0
        case 6:
            red = CGFloat(int >> 16) / 255
            green = CGFloat(int >> 8 & 0xFF) / 255
            blue = CGFloat(int & 0xFF) / 255
            alpha = 1.0
        case 8:
            red = CGFloat(int >> 24) / 255
            green = CGFloat(int >> 16 & 0xFF) / 255
            blue = CGFloat(int >> 8 & 0xFF) / 255
            alpha = CGFloat(int & 0xFF) / 255
        default:
            (red, green, blue, alpha) = (1, 1, 1, 1)
        }
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    static func dynamic(lightHex: String, darkHex: String) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: darkHex) : UIColor(hex: lightHex)
        }
    }
}
