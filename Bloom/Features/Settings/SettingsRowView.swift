//
//  SettingsRowView.swift
//  Bloom
//

import SwiftUI

struct SettingsRowView<Trailing: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let tint: SettingsTint
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: SettingsLayout.rowIconSpacing) {
            SettingsIconBadge(icon: icon, tint: tint)

            Text(title)
                .font(.system(size: SettingsLayout.rowFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.colors.text)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: Theme.spacing.micro)

            trailing
        }
        .contentShape(Rectangle())
    }
}

struct SettingsRowValue: View {
    private let text: Text

    init(value: String) {
        text = Text(value)
    }

    init(value: LocalizedStringKey) {
        text = Text(value)
    }

    var body: some View {
        HStack(spacing: Theme.spacing.micro) {
            text
                .font(.system(size: SettingsLayout.valueFontSize, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.colors.secondaryText)
                .lineLimit(1)

            SettingsChevron()
        }
    }
}

struct SettingsChevron: View {
    var size: CGFloat = SettingsLayout.chevronSize
    var color: Color = Theme.colors.secondaryText

    var body: some View {
        Image("chevron.right")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}

extension View {
    /// One row shape for every Settings section: insets, separator start and card background.
    func settingsRowStyle() -> some View {
        let separatorLeading = SettingsLayout.separatorLeading

        return listRowInsets(
            EdgeInsets(
                top: SettingsLayout.rowVerticalInset,
                leading: SettingsLayout.rowHorizontalInset,
                bottom: SettingsLayout.rowVerticalInset,
                trailing: SettingsLayout.rowHorizontalInset
            )
        )
        .alignmentGuide(.listRowSeparatorLeading) { _ in separatorLeading }
        .listRowBackground(Theme.colors.foreground)
    }
}
