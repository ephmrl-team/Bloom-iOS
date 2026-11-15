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
    /// Width the copy wraps at, which is narrower than the page so the paragraph stays tight.
    var textWidth: CGFloat?
    /// Delay of the tile entrance, so the side tiles follow the centred one.
    var tileDelay: Double = 0
    var appeared: Bool = true
    @ViewBuilder var icon: Icon

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var distance: CGFloat {
        min(abs(progress), 1)
    }

    private var scale: CGFloat {
        1 - distance * 0.05
    }

    private var tileOpacity: Double {
        (1 - Double(distance) * 0.3) * (appeared ? 1 : 0)
    }

    private var textFade: Double {
        (1 - Double(min(abs(progress) * 2, 1))) * (appeared ? 1 : 0)
    }

    /// Same entrance as the buttons in the footer: a short rise with a blur fade.
    private func enter(_ delay: Double) -> Animation? {
        reduceMotion ? nil : .smooth(duration: 0.6).delay(delay)
    }

    private var appearOffset: CGFloat {
        appeared || reduceMotion ? 0 : 16
    }

    private var appearBlur: CGFloat {
        appeared || reduceMotion ? 0 : 8
    }

    var body: some View {
        VStack(spacing: Theme.spacing.xxl) {
            Spacer()

            icon
                .frame(width: 138, height: 138)
                .scaleEffect(scale)
                .rotation3DEffect(.degrees(Double(progress) * -18), axis: (0, 1, 0), perspective: 0.5)
                .rotationEffect(.degrees(Double(progress) * 10))
                .offset(y: distance * 15 + appearOffset)
                .blur(radius: distance * 8 + appearBlur)
                .opacity(tileOpacity)
                .animation(enter(tileDelay), value: appeared)

            VStack(spacing: Theme.spacing.sm) {
                title
                    .multilineTextAlignment(.center)
                    .opacity(textFade)
                    .offset(y: appearOffset)
                    .blur(radius: appearBlur)
                    .animation(enter(0.1), value: appeared)

                Text(subtitle)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(textFade)
                    .offset(y: appearOffset)
                    .blur(radius: appearBlur)
                    .animation(enter(0.18), value: appeared)
            }
            .frame(width: textWidth)
            // The copy clears out sooner than the tile it belongs to.
            .offset(x: -progress * 60)

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
            // Rasterised once so scrolling and the side-tile blur do not redraw the gradient.
            .drawingGroup()
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
