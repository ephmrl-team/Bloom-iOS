//
//  SettingsEncryptionKeysView.swift
//  Bloom
//

import SwiftUI

struct SettingsEncryptionKeysView: View {
    @Environment(BloomManager.self) private var bloomManager

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: SettingsLayout.rowIconSpacing) {
                    SettingsIconBadge(icon: "shield", tint: .green)

                    Text("These keys identify your device. They are public and safe to share.")
                        .font(
                            .system(
                                size: SettingsLayout.valueFontSize,
                                weight: .regular,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Theme.colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .settingsRowStyle()
            }

            if let user = bloomManager.currentUser {
                keySection("ML-KEM", key: user.mlKemPublicKey)
                keySection("X448", key: user.ecdhPublicKey)
                keySection("Ed448", key: user.edPublicKey)
            } else {
                Text("No keys available.")
                    .font(.system(size: SettingsLayout.rowFontSize, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.colors.secondaryText)
                    .settingsRowStyle()
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(SettingsLayout.sectionSpacing)
        .scrollContentBackground(.hidden)
        .background(Theme.colors.background)
        .scrollEdgeEffectHidden(true, for: .all)
        .contentMargins(.bottom, SettingsLayout.bottomContentMargin, for: .scrollContent)
        .toolbarTitle("Encryption keys")
        .topVariableBlur()
    }

    private func keySection(_ title: String, key: String) -> some View {
        Section {
            Text(key)
                .font(.system(size: SettingsLayout.keyFontSize, weight: .regular, design: .monospaced))
                .foregroundStyle(Theme.colors.text)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .settingsRowStyle()
        } header: {
            Text(verbatim: title)
        }
    }
}
