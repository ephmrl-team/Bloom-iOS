//
//  WelcomePageView.swift
//  Bloom
//

import SwiftUI

struct WelcomePageView<Icon: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    /// 0 while the page is centred, ±1 once it is a full page away.
    var progress: CGFloat = 0
    var width: CGFloat?
    @ViewBuilder var icon: Icon

    private var distance: CGFloat {
        min(abs(progress), 1)
    }

    var body: some View {
        VStack(spacing: Theme.spacing.xxl) {
            Spacer()

            icon
                .frame(width: 138, height: 138)
                .rotation3DEffect(.degrees(Double(progress) * -18), axis: (0, 1, 0), perspective: 0.4)
                .scaleEffect(1 - distance * 0.12)
                .blur(radius: distance * 8)
                .opacity(1 - Double(distance) * 0.5)

            VStack(spacing: Theme.spacing.md - 2) {
                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(.headline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            // The copy trails behind the tile, so it leaves the screen sooner.
            .offset(x: -progress * 90)
            .opacity(1 - Double(distance) * 0.85)

            Spacer()
        }
        .padding(.horizontal, 36)
        .frame(width: width)
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
            .shadow(color: .black.opacity(0.2), radius: 20, x: 4, y: 4)
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
