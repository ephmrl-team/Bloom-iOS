//
//  SettingsAboutView.swift
//  Bloom
//

import SwiftUI

struct SettingsAboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: Theme.spacing.md) {
                    Image("logo")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: SettingsLayout.aboutLogoSize, height: SettingsLayout.aboutLogoSize)
                        .foregroundStyle(Theme.colors.primary)

                    Text(verbatim: "Bloom")
                        .font(.system(size: SettingsLayout.aboutTitleFontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.colors.text)

                    Text("Version \(version) (\(build))")
                        .font(.system(size: SettingsLayout.valueFontSize, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacing.xl)
                .listRowBackground(Theme.colors.foreground)
            }

            Section {
                Text("Bloom is free software distributed under the terms of the GNU General Public License, version 3.")
                    .font(.system(size: SettingsLayout.rowFontSize, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.colors.text)
                    .padding(.vertical, Theme.spacing.xs)
                    .settingsRowStyle()
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(SettingsLayout.sectionSpacing)
        .scrollContentBackground(.hidden)
        .background(Theme.colors.background)
        .scrollEdgeEffectHidden(true, for: .all)
        .contentMargins(.bottom, SettingsLayout.bottomContentMargin, for: .scrollContent)
        .toolbarTitle("About")
        .topVariableBlur()
    }
}
