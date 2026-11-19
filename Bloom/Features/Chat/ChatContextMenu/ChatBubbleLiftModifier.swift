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

    /// Short enough to feel instant, long enough not to fire while the list scrolls.
    private static let pressDuration: TimeInterval = 0.32

    @Environment(ChatContextMenuModel.self) private var contextMenu: ChatContextMenuModel?
    @Environment(KeyboardTracker.self) private var keyboard: KeyboardTracker?
    /// A reference box: geometry updates while scrolling must not re-render the row.
    @State private var anchor = LiftAnchor()
    /// Held down, before the menu opens: the message dims so the press is answered at once.
    @State private var pressing = false

    func body(content: Content) -> some View {
        let liftable = content
            .opacity(pressing ? 0.55 : 1)
            .animation(.easeOut(duration: 0.12), value: pressing)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { anchor.frame = $0 }
            .onLongPressGesture(
                minimumDuration: Self.pressDuration,
                maximumDistance: 14,
                perform: lift,
                onPressingChanged: { pressing = $0 }
            )

        if isLifted {
            liftable.hidden()
        } else {
            liftable
        }
    }

    private func lift() {
        guard let contextMenu, !isLifted, anchor.frame.width > 0, anchor.frame.height > 0 else { return }
        // The keyboard leaves first so the backdrop covers the whole screen; the messages hold still.
        keyboard?.suspendForContextMenu()
        contextMenu.present(item: item, anchor: anchor.frame, actions: actions)
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
