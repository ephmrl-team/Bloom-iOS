//
//  WelcomePageView.swift
//  Bloom
//

import SwiftUI

struct WelcomePageView<Icon: View>: View {
    let title: Text
    let subtitle: LocalizedStringKey
    /// Width the copy wraps at, which is narrower than the page so the paragraph stays tight.
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
                    let distance = min(abs(phase.value), 1)
                    return content
                        .scaleEffect(1 - distance * 0.05)
                        .rotationEffect(.degrees(-phase.value * 10))
                        .offset(y: distance * 15)
                        .opacity(1 - distance * 0.45)
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
            // The copy clears out sooner than the tile it belongs to.
            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                content
                    .offset(x: phase.value * 60)
                    // Only the centred copy is readable; the neighbours never bleed through.
                    .opacity(abs(phase.value) < 0.05 ? 1 : 0)
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
