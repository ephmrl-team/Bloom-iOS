//
//  WelcomePageView.swift
//  Bloom
//

import SwiftUI

struct WelcomePageView<Icon: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @ViewBuilder var icon: Icon

    var body: some View {
        VStack(spacing: Theme.spacing.xxl) {
            Spacer()

            icon
                .frame(width: 128, height: 128)

            VStack(spacing: Theme.spacing.md - 2) {
                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(.headline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, 36)
    }
}

struct WelcomeFeatureTile: View {
    let feature: WelcomeFeature

    var body: some View {
        RoundedRectangle(cornerRadius: 32)
            .fill(feature.gradient)
            .overlay {
                Image(feature.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(feature.iconColor)
                    .shadow(color: .white.opacity(0.55), radius: 0.5, y: 1)
                    .shadow(color: .black.opacity(0.16), radius: 1.5, y: -0.5)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 40) {
        WelcomePageView(title: "Private chats", subtitle: "Messages are encrypted") {
            WelcomeFeatureTile(feature: WelcomeFeature.all[0])
        }
        .frame(height: 320)
    }
}
