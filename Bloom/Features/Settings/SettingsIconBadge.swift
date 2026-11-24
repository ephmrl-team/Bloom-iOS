//
//  SettingsIconBadge.swift
//  Bloom
//

import SwiftUI

/// A 30 pt tile with a soft gradient and a darker icon, mirroring `WelcomeFeatureTile`.
struct SettingsIconBadge: View {
    let icon: String
    let tint: SettingsTint

    var body: some View {
        RoundedRectangle(cornerRadius: SettingsLayout.badgeRadius, style: .continuous)
            .fill(tint.gradient)
            .overlay {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: SettingsLayout.badgeIconSize, height: SettingsLayout.badgeIconSize)
                    .foregroundStyle(tint.iconColor)
                    .shadow(
                        color: Theme.colors.white.opacity(SettingsLayout.iconHighlightOpacity),
                        radius: SettingsLayout.iconHighlightRadius,
                        y: 1
                    )
                    .shadow(
                        color: Theme.colors.black.opacity(SettingsLayout.iconShadeOpacity),
                        radius: SettingsLayout.iconShadeRadius,
                        y: SettingsLayout.iconShadeOffset
                    )
            }
            .frame(width: SettingsLayout.badgeSize, height: SettingsLayout.badgeSize)
            .accessibilityHidden(true)
    }
}
