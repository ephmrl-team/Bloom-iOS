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
    let configuration: ChatMenuConfiguration
    let onSelect: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(configuration.reactions.enumerated()), id: \.offset) { index, reaction in
                reactionButton(reaction, index: index)
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

    /// The stagger only plays on the way in: dismissal stays one quick beat.
    private func animation(_ index: Int) -> Animation {
        guard !reduceMotion else {
            return .easeOut(duration: 0.1)
        }
        let middle = Double(configuration.reactions.count - 1) / 2
        let delay = shown ? abs(Double(index) - middle) * 0.03 : 0
        return configuration.controlAnimation.delay(delay)
    }
}
