//
//  WelcomePageView.swift
//  Bloom
//

import SwiftUI

struct WelcomePageView<Icon: View>: View {
    let title: Text
    let subtitle: LocalizedStringKey
    /// Width the copy wraps at. Must fit inside the page cell, otherwise the neighbouring
    /// copy overhangs into the side gaps and shows up next to the centred tile.
    var textWidth: CGFloat?
    /// Delay of the tile entrance, so the side tiles follow the centred one.
    var tileDelay: Double = 0
    var appeared: Bool = true
    @ViewBuilder var icon: Icon

    var body: some View {
        VStack(spacing: Theme.spacing.xxl) {
            Spacer()

            icon
                .frame(width: 138, height: 138)
                .compositingGroup()
                // Native scroll transition: the transform is driven by the scroll view,
                // so the pages are rasterised once instead of rebuilding every frame.
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    // Sine easing: the effect still moves at full rate as the page reaches
                    // the centre, so it glides into the resting spot instead of stopping
                    // early and then snapping once the scroll view settles.
                    let progress = max(-1, min(1, phase.value))
                    let eased = sin(abs(progress) * .pi / 2)
                    return content
                        .scaleEffect(1 - eased * 0.08)
                        .rotationEffect(.degrees(-progress * 8))
                        .offset(y: eased * 14)
                        .blur(radius: eased * 6)
                        .opacity(1 - eased * 0.4)
                }
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(.smooth(duration: 0.75).delay(tileDelay), value: appeared)

            VStack(spacing: Theme.spacing.sm) {
                title
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: textWidth)
            .compositingGroup()
            // The copy stays inside its own page and clears out early, so the neighbour's
            // title and subtitle never show up in the gaps beside the centred tile.
            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                content
                    .offset(x: phase.value * 24)
                    .opacity(1 - min(abs(phase.value) * 6, 1))
            }
            .offset(y: appeared ? 0 : 16)
            .opacity(appeared ? 1 : 0)
            .animation(.smooth(duration: 0.75).delay(0.14), value: appeared)

            Spacer()
        }
    }
}

struct WelcomeFeatureTile: View {
    let feature: WelcomeFeature

    var body: some View {
        RoundedRectangle(cornerRadius: 34)
            .fill(feature.gradient)
            .overlay {
                Image(feature.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 82)
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
            title: Text("Easy conversations").font(.system(size: 32, weight: .semibold, design: .rounded)),
            subtitle: "Voice notes, quick replies and a clean interface",
            textWidth: 313
        ) {
            WelcomeFeatureTile(feature: WelcomeFeature.all[1])
        }
        .frame(height: 320)
    }
}
