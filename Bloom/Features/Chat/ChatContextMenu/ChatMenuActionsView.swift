//
//  ChatMenuActionsView.swift
//  Bloom
//

import SwiftUI

/// Copy / Reply / Forward (and Delete for own messages) under the lifted bubble.
struct ChatMenuActionsView: View {
    let actions: ChatMenuActions
    let shown: Bool
    let blur: CGFloat
    let configuration: ChatMenuConfiguration
    let onSelect: (ChatMenuAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(.copy, title: "Copy", symbol: "doc.on.doc")
            divider
            row(.reply, title: "Reply", symbol: "arrowshape.turn.up.left")
            divider
            row(.forward, title: "Forward", symbol: "arrowshape.turn.up.right")
            if actions.delete != nil {
                divider
                row(.delete, title: "Delete", symbol: "trash", destructive: true)
            }
        }
        .padding(.vertical, configuration.actionsPadding)
        .blur(radius: blur)
        .opacity(shown ? 1 : 0)
        .animation(configuration.controlAnimation, value: shown)
    }

    private func row(
        _ action: ChatMenuAction,
        title: LocalizedStringKey,
        symbol: String,
        destructive: Bool = false
    ) -> some View {
        Button { onSelect(action) } label: {
            HStack(spacing: Theme.spacing.md) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .regular))
                    .frame(width: 22)
                Text(title)
                    .font(.system(.body, design: .rounded))
                Spacer(minLength: 0)
            }
            .foregroundStyle(destructive ? Theme.colors.red : Theme.colors.text)
            .padding(.horizontal, Theme.spacing.xl)
            .frame(height: configuration.rowHeight)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.colors.border)
            .frame(height: configuration.dividerHeight)
    }
}
