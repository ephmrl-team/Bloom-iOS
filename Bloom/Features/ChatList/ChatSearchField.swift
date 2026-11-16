//
//  ChatSearchField.swift
//  Bloom
//

import SwiftUI

/// The expanded search field shown in the native toolbar.
struct ChatSearchField: View {
    @Binding var text: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.spacing.sm) {
            icon("magnifyingglass", size: 18)

            TextField("Search", text: $text)
                .font(.system(.body, design: .rounded))
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("searchField")
        }
        .padding(.horizontal, Theme.spacing.md)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .glassEffect(.regular, in: Capsule())
        .onAppear { isFocused = true }
    }

    private func icon(_ name: String, size: CGFloat) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(Theme.colors.secondaryText)
    }
}

#Preview {
    @Previewable @State var text = ""

    ChatSearchField(text: $text)
        .padding()
}
