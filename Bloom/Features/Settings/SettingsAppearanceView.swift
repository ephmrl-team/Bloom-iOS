//
//  SettingsAppearanceView.swift
//  Bloom
//

import SwiftUI

struct SettingsAppearanceView: View {
    @AppStorage(AppearanceMode.storageKey) private var modeRaw = AppearanceMode.system.rawValue
    @AppStorage(ClearGlassSetting.storageKey) private var clearGlass = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AppearancePreviewCard()

                sectionHeader("Theme")
                    .padding(.top, SettingsLayout.sectionSpacing)

                themeCard
                    .padding(.top, SettingsLayout.captionSpacing)

                sectionHeader("Clear Liquid Glass (Experimental)")
                    .padding(.top, SettingsLayout.sectionSpacing)

                clearGlassCard
                    .padding(.top, SettingsLayout.captionSpacing)

                caption
                    .padding(.horizontal, SettingsLayout.captionInset)
                    .padding(.top, SettingsLayout.captionSpacing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.spacing.lg)
            .padding(.vertical, Theme.spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .background(Theme.colors.background)
        .scrollEdgeEffectHidden(true, for: .all)
        .contentMargins(.bottom, SettingsLayout.bottomContentMargin, for: .scrollContent)
        .toolbarTitle("Appearance")
        .topVariableBlur()
    }

    private var themeCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(AppearanceMode.allCases.enumerated()), id: \.element.id) { index, mode in
                Button {
                    modeRaw = mode.rawValue
                } label: {
                    themeRow(mode)
                }
                .buttonStyle(.plain)

                if index < AppearanceMode.allCases.count - 1 {
                    separator
                }
            }
        }
        .background(Theme.colors.foreground, in: shape)
    }

    private func themeRow(_ mode: AppearanceMode) -> some View {
        HStack(spacing: SettingsLayout.rowIconSpacing) {
            Image(iconName(for: mode))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: SettingsLayout.appearanceIconSize, height: SettingsLayout.appearanceIconSize)
                .foregroundStyle(Theme.colors.secondaryText)

            Text(mode.title)
                .font(.system(size: SettingsLayout.rowFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.colors.text)

            Spacer(minLength: Theme.spacing.micro)

            SettingsSelectionMark(isSelected: modeRaw == mode.rawValue)
        }
        .padding(.horizontal, SettingsLayout.rowHorizontalInset)
        .frame(height: SettingsLayout.appearanceRowHeight)
        .contentShape(Rectangle())
    }

    private var separator: some View {
        Rectangle()
            .fill(Theme.colors.border)
            .frame(height: SettingsLayout.appearanceSeparatorHeight)
            .padding(.leading, SettingsLayout.rowHorizontalInset)
    }

    private var clearGlassCard: some View {
        Toggle(isOn: $clearGlass) {
            Text("Enable Clear Liquid Glass")
                .font(.system(size: SettingsLayout.rowFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.colors.text)
        }
        .tint(Theme.colors.primary)
        .padding(.horizontal, SettingsLayout.rowHorizontalInset)
        .frame(height: SettingsLayout.appearanceRowHeight)
        .background(Theme.colors.foreground, in: shape)
    }

    private var caption: some View {
        Text("Enabling this feature may cause problems such as app crash, UI blinking and accessibility")
            .font(.system(size: SettingsLayout.captionFontSize, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.colors.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: SettingsLayout.rowFontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.colors.secondaryText)
            .padding(.horizontal, SettingsLayout.captionInset)
    }

    private func iconName(for mode: AppearanceMode) -> String {
        switch mode {
        case .system: "circle.half"
        case .light: "sun"
        case .dark: "moon"
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.radius.xl, style: .continuous)
    }
}

struct SettingsSelectionMark: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? Theme.colors.primary : Theme.colors.secondaryText,
                    lineWidth: SettingsLayout.selectionMarkLineWidth
                )
                .frame(width: SettingsLayout.selectionMarkSize, height: SettingsLayout.selectionMarkSize)

            if isSelected {
                Circle()
                    .fill(Theme.colors.primary)
                    .frame(
                        width: SettingsLayout.selectionMarkInnerSize,
                        height: SettingsLayout.selectionMarkInnerSize
                    )
            }
        }
        .animation(.smooth(duration: 0.32), value: isSelected)
        .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            SettingsAppearanceView()
        }
    }
#endif
