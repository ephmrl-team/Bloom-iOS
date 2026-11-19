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

    /// One finger, one highlight: it slides to the row under the finger and runs it on release.
    @State private var hovered: ChatMenuAction?
    /// Kept while the highlight fades, so it never slides back to the first row.
    @State private var hoveredIndex = 0

    private var rows: [ChatMenuAction] {
        actions.delete == nil ? [.copy, .reply, .forward] : [.copy, .reply, .forward, .delete]
    }

    var body: some View {
        ZStack(alignment: .top) {
            highlight
            VStack(spacing: configuration.rowSpacing) {
                ForEach(rows, id: \.self) { action in
                    if action == .delete {
                        divider
                    }
                    row(action)
                }
            }
        }
        .contentShape(.rect)
        .gesture(drag)
        .padding(.vertical, configuration.menuEdgePadding)
        .blur(radius: blur)
        .opacity(shown ? 1 : 0)
        .animation(configuration.controlAnimation, value: shown)
    }

    private var highlight: some View {
        Capsule()
            .fill(Color.primary.opacity(0.1))
            .frame(height: configuration.rowHeight)
            .padding(.horizontal, configuration.rowInset)
            .offset(y: top(of: hoveredIndex))
            .opacity(hovered == nil ? 0 : 1)
            .animation(.easeOut(duration: 0.1), value: hovered)
            .allowsHitTesting(false)
    }

    private func row(_ action: ChatMenuAction) -> some View {
        HStack(spacing: configuration.iconSpacing) {
            Image(symbol(for: action))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: configuration.iconSize, height: configuration.iconSize)
            Text(title(for: action))
                .font(.system(size: configuration.rowFontSize, design: .rounded))
            Spacer(minLength: 0)
        }
        .foregroundStyle(action == .delete ? Theme.colors.red : Theme.colors.text)
        .padding(.horizontal, configuration.rowInset + configuration.rowContentInset)
        .frame(height: configuration.rowHeight)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onSelect(action) }
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.colors.border)
            .frame(height: configuration.dividerHeight)
            .padding(.horizontal, configuration.rowInset + configuration.rowContentInset)
            .padding(.vertical, configuration.dividerSpacing)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let action = action(at: value.location.y), action != hovered else { return }
                let isFirstPress = hovered == nil
                hovered = action
                if isFirstPress {
                    hoveredIndex = rows.firstIndex(of: action) ?? 0
                } else {
                    withAnimation(.smooth(duration: 0.18)) {
                        hoveredIndex = rows.firstIndex(of: action) ?? 0
                    }
                }
                ChatMenuHaptics.select()
            }
            .onEnded { value in
                let action = action(at: value.location.y)
                hovered = nil
                if let action {
                    onSelect(action)
                }
            }
    }

    /// The row under the finger, with the gaps snapping to the nearer one.
    private func action(at locationY: CGFloat) -> ChatMenuAction? {
        let slack = configuration.rowSpacing / 2
        for (index, action) in rows.enumerated() {
            let top = top(of: index)
            if locationY >= top - slack, locationY < top + configuration.rowHeight + slack {
                return action
            }
        }
        return nil
    }

    /// Delete is preceded by the divider, which takes a slot, its own padding and a gap of its own.
    private func top(of index: Int) -> CGFloat {
        let step = configuration.rowHeight + configuration.rowSpacing
        let rule = configuration.dividerHeight + configuration.dividerSpacing * 2
        return CGFloat(index) * step + (index > 2 ? rule + configuration.rowSpacing : 0)
    }

    private func title(for action: ChatMenuAction) -> LocalizedStringKey {
        switch action {
        case .copy: "Copy"
        case .reply: "Reply"
        case .forward: "Forward"
        case .delete: "Delete"
        }
    }

    private func symbol(for action: ChatMenuAction) -> String {
        switch action {
        case .copy: "square.and.pencil"
        case .reply: "chat.bubbles"
        case .forward: "chevron.right"
        case .delete: "x.mark"
        }
    }
}
