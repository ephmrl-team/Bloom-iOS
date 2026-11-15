//
//  WelcomePageView.swift
//  Bloom
//

import SwiftUI

struct WelcomePageView<Icon: View>: View {
    let title: Text
    let subtitle: LocalizedStringKey
    /// Width the copy wraps at: wider than the page so the paragraph stays on two lines,
    /// as in the design. The neighbouring copies are faded out by `progress`, so the
    /// overhang never shows up beside the centred tile.
    var textWidth: CGFloat?
    /// Width of one page, used to normalise the distance to the centre of the carousel.
    var pageWidth: CGFloat = 0
    /// Centre of the carousel, measured by the parent, so no scroll-view offset is needed.
    var containerMidX: CGFloat = 0
    /// Delay of the tile entrance, so the side tiles follow the centred one.
    var tileDelay: Double = 0
    var appeared: Bool = true
    @ViewBuilder var icon: Icon

    /// Where this page sits relative to the centre: 0 when it fills the middle, ±1 when a
    /// neighbour does. Read from the page's own frame, because the scroll view's phase
    /// says "identity" for every page that is merely on screen.
    @State private var midX: CGFloat?

    private var progress: CGFloat {
        guard pageWidth > 0, let midX else { return 0 }
        return min(max((midX - containerMidX) / pageWidth, -1), 1)
    }

    private var distance: CGFloat {
        abs(progress)
    }

    var body: some View {
        VStack(spacing: Theme.spacing.xxl) {
            Spacer()

            icon
                .frame(width: 138, height: 138)
                .compositingGroup()
                // Linear in `progress`, the rate the copy moves at too: the tile and the
                // text travel together instead of the tile easing off on its own, which
                // made it look like it parked and then jumped.
                .scaleEffect(1 - distance * 0.1)
                .rotationEffect(.degrees(progress * 10))
                .offset(y: distance * 16)
                .blur(radius: distance * 8)
                .opacity(1 - Double(distance) * 0.35)
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
            // The copy travels faster than the tile, and the neighbours' copies are a
            // full page apart, so theirs reach zero exactly as the centred one does: at
            // any moment only the page nearest the middle shows text, but it does not
            // blink out on the first few points of a swipe.
            .offset(x: progress * 80)
            .opacity(1 - min(Double(distance) * 2, 1))
            .offset(y: appeared ? 0 : 16)
            .opacity(appeared ? 1 : 0)
            .animation(.smooth(duration: 0.75).delay(0.14), value: appeared)

            Spacer()
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .global).midX
        } action: { newValue in
            midX = newValue
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
