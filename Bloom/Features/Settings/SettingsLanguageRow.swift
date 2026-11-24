//
//  SettingsLanguageRow.swift
//  Bloom
//

import SwiftUI
import UIKit

/// Shows the real system language and hands the language switch to iOS.
struct SettingsLanguageRow: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(url)
        } label: {
            SettingsRowView(title: "Language", icon: "globe", tint: .cyan) {
                SettingsRowValue(value: languageName)
            }
        }
        .buttonStyle(.plain)
    }

    private var languageName: String {
        let code = Locale.current.language.languageCode?.identifier
            ?? Locale.current.identifier
        guard let name = Locale.current.localizedString(forLanguageCode: code) else {
            return code.uppercased()
        }
        return name.capitalized(with: .current)
    }
}
