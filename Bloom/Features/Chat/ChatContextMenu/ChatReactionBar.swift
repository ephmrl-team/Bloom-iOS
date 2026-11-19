//
//  ChatReactionBar.swift
//  Bloom
//

import SwiftUI

/// Quick tapbacks above the lifted bubble. The active reaction stays highlighted.
struct ChatReactionBar: View {
    let selected: String?
    let shown: Bool
    let blur: CGFloat
    /// Own messages open their bar from the right, incoming ones from the left.
    let isMine: Bool
    let configuration: ChatMenuConfiguration
    let onSelect: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(configuration.reactions.indices, id: \.self) { index in
                reactionButton(configuration.reactions[index], index: index)
            }
        }
        .padding(configuration.reactionPadding)
        .blur(radius: reduceMotion ? 0 : blur)
    }

    private func reactionButton(_ reaction: String, index: Int) -> some View {
        Button { onSelect(reaction) } label: {
            Text(reaction)
                .font(.system(size: configuration.reactionItemSize * 0.55))
                .frame(width: configuration.reactionItemSize, height: configuration.reactionItemSize)
                .background(selected == reaction ? Theme.colors.glassBackdrop : .clear, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(reaction))
        .scaleEffect(shown || reduceMotion ? 1 : 0.35)
        .opacity(shown ? 1 : 0)
        .animation(animation(index), value: shown)
    }

    /// The stagger runs from the side the message sits on and only plays on the way in.
    private func animation(_ index: Int) -> Animation {
        guard !reduceMotion else {
            return .easeOut(duration: 0.1)
        }
        guard shown else {
            return configuration.controlAnimation
        }
        let order = isMine ? configuration.reactions.count - 1 - index : index
        return configuration.controlAnimation.delay(Double(order + 1) * 0.05)
    }
}
