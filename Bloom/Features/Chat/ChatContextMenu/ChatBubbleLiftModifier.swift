//
//  ChatBubbleLiftModifier.swift
//  Bloom
//

import SwiftUI

/// Long-press hand-off: the bubble reports its window frame and asks the overlay to lift it.
struct ChatBubbleLiftModifier: ViewModifier {
    let item: MessageItem
    let isLifted: Bool
    let actions: ChatMenuActions

    @Environment(ChatContextMenuModel.self) private var contextMenu: ChatContextMenuModel?
    @Environment(KeyboardTracker.self) private var keyboard: KeyboardTracker?
    /// A reference box: geometry updates while scrolling must not re-render the row.
    @State private var anchor = LiftAnchor()

    func body(content: Content) -> some View {
        let liftable = content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { anchor.frame = $0 }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.4).onEnded { _ in lift() }
            )

        if isLifted {
            liftable.hidden()
        } else {
            liftable
        }
    }

    private func lift() {
        guard let contextMenu, !isLifted, anchor.frame.width > 0, anchor.frame.height > 0 else { return }
        contextMenu.present(
            item: item,
            anchor: anchor.frame,
            actions: actions,
            keyboardHeight: keyboard?.visibleHeight
        )
    }
}

extension View {
    func chatBubbleLift(item: MessageItem, isLifted: Bool, actions: ChatMenuActions) -> some View {
        modifier(ChatBubbleLiftModifier(item: item, isLifted: isLifted, actions: actions))
    }
}

/// Plain box so per-frame geometry writes stay out of SwiftUI state.
private final class LiftAnchor {
    var frame: CGRect = .zero
}
