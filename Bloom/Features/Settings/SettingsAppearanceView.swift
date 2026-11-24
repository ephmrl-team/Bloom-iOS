//
//  SettingsAppearanceView.swift
//  Bloom
//

import SwiftUI

struct SettingsAppearanceView: View {
    @AppStorage(AppearanceMode.storageKey) private var modeRaw = AppearanceMode.system.rawValue

    var body: some View {
        List {
            Section {
                HStack(spacing: Theme.spacing.md) {
                    AvatarView(size: .md, id: "appearance-preview", name: "Bloom")

                    VStack(alignment: .leading, spacing: SettingsLayout.profileNameSpacing) {
                        Text(verbatim: "Bloom")
                            .font(
                                .system(
                                    size: SettingsLayout.rowFontSize,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(Theme.colors.text)

                        Text("This is how your chats will look.")
                            .font(
                                .system(
                                    size: SettingsLayout.valueFontSize,
                                    weight: .regular,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(Theme.colors.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
                .settingsRowStyle()
            }

            Section {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        modeRaw = mode.rawValue
                    } label: {
                        HStack(spacing: Theme.spacing.md) {
                            Text(mode.title)
                                .font(
                                    .system(
                                        size: SettingsLayout.rowFontSize,
                                        weight: .regular,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(Theme.colors.text)

                            Spacer(minLength: Theme.spacing.sm)

                            SettingsSelectionMark(isSelected: modeRaw == mode.rawValue)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .settingsRowStyle()
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(SettingsLayout.sectionSpacing)
        .scrollContentBackground(.hidden)
        .background(Theme.colors.background)
        .scrollEdgeEffectHidden(true, for: .all)
        .contentMargins(.bottom, SettingsLayout.bottomContentMargin, for: .scrollContent)
        .toolbarTitle("Appearance")
        .topVariableBlur()
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
        .accessibilityHidden(true)
    }
}
