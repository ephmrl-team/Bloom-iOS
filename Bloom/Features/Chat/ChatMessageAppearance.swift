import SwiftUI

struct ChatMessageAppearance: View {
    let item: MessageItem
    let isSeen: Bool
    let onAnimated: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ChatContextMenuModel.self) private var contextMenu: ChatContextMenuModel?
    @State private var appeared: Bool

    init(item: MessageItem, isSeen: Bool, animate: Bool, onAnimated: @escaping () -> Void) {
        self.item = item
        self.isSeen = isSeen
        self.onAnimated = onAnimated
        // Only newly sent messages animate; loaded history is already visible.
        _appeared = State(initialValue: !animate)
    }

    var body: some View {
        ChatRowView(
            item: item,
            isSeen: isSeen,
            isLifted: contextMenu?.liftedRenderID == item.renderID
        )
        .equatable()
        .padding(.horizontal, Theme.spacing.lg)
        .opacity(appeared ? 1 : 0)
        .blur(radius: appeared || reduceMotion ? 0 : 10)
        .offset(y: appeared || reduceMotion ? 0 : 135)
        .onAppear {
            guard !appeared else { return }
            onAnimated()
            withAnimation(.smooth(duration: 0.235)) {
                appeared = true
            }
        }
    }
}
