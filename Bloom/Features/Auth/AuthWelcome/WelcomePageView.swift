//
//  WelcomePageView.swift
//  Bloom
//

import SwiftUI

struct WelcomePageView<Icon: View>: View {
    let title: Text
    let subtitle: LocalizedStringKey
    /// 0 while the page is centred, ±1 once it is a full page away.
    var progress: CGFloat = 0
    /// Width the copy wraps at, which is wider than the page itself so it stays on two lines.
    var textWidth: CGFloat?
    @ViewBuilder var icon: Icon

    private var distance: CGFloat {
        min(abs(progress), 1)
    }

    var body: some View {
        VStack(spacing: Theme.spacing.xxl) {
            Spacer()

            icon
                .frame(width: 138, height: 138)
                .scaleEffect(1 - distance * 0.08)
                .rotation3DEffect(.degrees(Double(progress) * -12), axis: (0, 1, 0), perspective: 0.5)
                .blur(radius: distance * 14)
                .opacity(1 - Double(distance) * 0.5)

            VStack(spacing: Theme.spacing.sm) {
                title
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(.headline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: textWidth)
            // The copy clears out sooner than the tile it belongs to.
            .offset(x: -progress * 60)
            .opacity(1 - Double(min(abs(progress) * 2, 1)))

            Spacer()
        }
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
        WelcomePageView(
            title: Text("Easy conversations").font(.system(.largeTitle, design: .rounded, weight: .semibold)),
            subtitle: "Voice notes, quick replies and a clean interface",
            textWidth: 340
        ) {
            WelcomeFeatureTile(feature: WelcomeFeature.all[0])
        }
        .frame(height: 320)
    }
}
