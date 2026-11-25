//
//  AppearanceAccentPicker.swift
//  Bloom
//

import SwiftUI

/// The accent band under the chat preview. A tap interpolates the app accent natively and, when
/// the two swatches are neighbours, hands the dots over to a metaball bridge. Tapping again while
/// a bridge runs fades that bridge out and starts the next one from the current selection.
struct AppearanceAccentPicker: View {
    @AppStorage(AppAccent.storageKey) private var accentRaw = AppAccent.blue.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var layers: [GooeyLayer] = []

    private var selected: AppAccent {
        AppAccent(rawValue: accentRaw) ?? .blue
    }

    private var rowWidth: CGFloat {
        let count = AppAccent.allCases.count
        return CGFloat(count) * SettingsLayout.appearanceSwatchCellSize
            + CGFloat(count - 1) * SettingsLayout.appearanceSwatchSpacing
            + 2 * Theme.spacing.lg
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.appearanceAccentSpacing) {
            Text("Accent color")
                .font(.system(size: SettingsLayout.rowFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.colors.secondaryText)
                .padding(.horizontal, Theme.spacing.lg)

            ScrollView(.horizontal) {
                ZStack {
                    HStack(spacing: SettingsLayout.appearanceSwatchSpacing) {
                        ForEach(AppAccent.allCases) { accent in
                            swatch(accent)
                        }
                    }
                    .padding(.horizontal, Theme.spacing.lg)
                    .frame(width: rowWidth, height: SettingsLayout.appearanceSwatchCellSize)

                    ForEach(layers) { layer in
                        AccentGooeyView(transition: layer.transition, width: rowWidth)
                            .opacity(layer.opacity)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .frame(width: rowWidth, height: SettingsLayout.appearanceSwatchCellSize)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
        .padding(.vertical, Theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.colors.foreground)
    }

    private func swatch(_ accent: AppAccent) -> some View {
        let isSelected = selected == accent
        return Button {
            select(accent)
        } label: {
            swatchLabel(accent, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accent.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func swatchLabel(_ accent: AppAccent, isSelected: Bool) -> some View {
        ZStack {
            shadow(isSelected: isSelected)
                .animation(swatchAnimation, value: isSelected)

            swatchDot(accent, isSelected: isSelected)
        }
        .frame(width: SettingsLayout.appearanceSwatchCellSize, height: SettingsLayout.appearanceSwatchCellSize)
        .contentShape(Rectangle())
    }

    private func swatchDot(_ accent: AppAccent, isSelected: Bool) -> some View {
        Circle()
            .fill(accent.color)
            .overlay {
                Circle()
                    .strokeBorder(Theme.colors.border, lineWidth: SettingsLayout.appearanceCardBorderWidth)
            }
            .frame(width: SettingsLayout.appearanceSwatchSize, height: SettingsLayout.appearanceSwatchSize)
            .scaleEffect(isSelected ? SettingsLayout.appearanceSwatchSelectedScale : 1)
            .animation(swatchAnimation, value: isSelected)
            .opacity(dotOpacity(for: accent))
    }

    private var swatchAnimation: Animation? {
        reduceMotion ? nil : .bouncy(duration: 0.5, extraBounce: 0.3)
    }

    /// A soft black shadow with a 4 pt spread, built by blurring a larger circle.
    private func shadow(isSelected: Bool) -> some View {
        Circle()
            .fill(Theme.colors.black.opacity(SettingsLayout.appearanceSwatchShadowOpacity))
            .frame(
                width: SettingsLayout.appearanceSwatchSize + 2 * SettingsLayout.appearanceSwatchShadowSpread,
                height: SettingsLayout.appearanceSwatchSize + 2 * SettingsLayout.appearanceSwatchShadowSpread
            )
            .blur(radius: SettingsLayout.appearanceSwatchShadowRadius)
            .opacity(isSelected ? 1 : 0)
    }

    /// A dot drawn by a bridge is hidden; when that bridge fades, the real dot fades back in.
    private func dotOpacity(for accent: AppAccent) -> Double {
        layers.reduce(1.0) { opacity, layer in
            guard layer.transition.hides(accent) else {
                return opacity
            }
            return min(opacity, 1 - layer.opacity)
        }
    }

    private func select(_ accent: AppAccent) {
        guard accent != selected else { return }
        let from = selected
        let adjacent = from.isAdjacent(to: accent)

        if adjacent, !reduceMotion {
            withAnimation(.smooth(duration: 0.34)) {
                accentRaw = accent.rawValue
            }
        } else {
            accentRaw = accent.rawValue
        }

        guard !reduceMotion else {
            layers.removeAll()
            return
        }

        fadeLayers()

        guard adjacent else {
            return
        }
        layers.append(GooeyLayer(transition: AccentTransition(id: UUID(), from: from, target: accent)))
    }

    private func fadeLayers() {
        guard !layers.isEmpty else { return }
        let fading = layers.map(\.id)
        withAnimation(.linear(duration: 0.12)) {
            for index in layers.indices {
                layers[index].opacity = 0
            }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            layers.removeAll { fading.contains($0.id) }
        }
    }
}

private struct GooeyLayer: Identifiable {
    let transition: AccentTransition
    var opacity: Double = 1

    var id: UUID {
        transition.id
    }
}

#if DEBUG
    #Preview {
        AppearanceAccentPicker()
            .background(Theme.colors.background)
    }
#endif
