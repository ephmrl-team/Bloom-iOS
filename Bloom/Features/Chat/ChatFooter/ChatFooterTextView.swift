//
//  ChatFooterTextView.swift
//  Bloom
//
//  Created by Аскольд on 16.08.2026.
//

import SwiftUI

struct ChatFooterTextView: View {
    @FocusState.Binding var focused: Bool
    @Binding var text: String

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text("Type a message...")
                .font(.system(.headline, design: .rounded, weight: .medium))
                .foregroundStyle(.primary),
            axis: .vertical
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1 ... 5)
        .focused($focused)
        .font(.system(.headline, design: .rounded, weight: .medium))
        .padding(.leading, Theme.spacing.lg)
        .padding(.trailing, Theme.spacing.md)
        .padding(.vertical, Theme.spacing.sm)
        .foregroundStyle(.primary)
        .textFieldStyle(.plain)
        .tint(Theme.colors.primary)
        .accessibilityLabel("Message")
        .accessibilityIdentifier("chatMessageField")
    }
}
