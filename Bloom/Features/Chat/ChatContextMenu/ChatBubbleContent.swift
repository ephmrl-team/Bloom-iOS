//
//  ChatBubbleContent.swift
//  Bloom
//

import SwiftUI

/// The message bubble itself. Shared by the row and by the lifted layer of the context menu, so the
/// transfer is identical for every content type (text, emoji, future media).
struct ChatBubbleContent: View {
    let item: MessageItem

    private enum Layout {
        static let bubbleCornerRadius: CGFloat = 22
        static let emojiOverlayCornerRadius: CGFloat = 20
        static let minBubbleWidth: CGFloat = 60
        static let minBubbleHeight: CGFloat = 40
        static let minEmojiSize: CGFloat = 32
    }

    private var textColor: Color {
        item.me ? Theme.colors.white : Theme.colors.text
    }

    private var backgroundColor: Color {
        item.me ? Theme.colors.primary : Color(.secondarySystemBackground)
    }

    private var emojiSize: CGFloat {
        let count = CGFloat(item.content.count)
        guard count > 0 else { return 0 }

        let size: CGFloat
        switch count {
        case 1:
            size = 120.0
        case 2:
            size = 80.0
        default:
            size = 120.0 / (count * 0.75)
        }

        return max(Layout.minEmojiSize, size)
    }

    var body: some View {
        if item.content.isOnlyEmojis {
            emojiBubble
        } else {
            textBubble
        }
    }

    private var emojiBubble: some View {
        Text(item.content)
            .font(.system(size: emojiSize, weight: .regular, design: .rounded))
            .padding(.bottom, item.content.isSingleEmoji ? 0 : Theme.spacing.xxl)
            .overlay(
                Text(item.date)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .foregroundColor(Theme.colors.text)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        .thinMaterial,
                        in: RoundedRectangle(cornerRadius: Layout.emojiOverlayCornerRadius)
                    ),
                alignment: item.me ? .bottomTrailing : .bottomLeading
            )
    }

    private var textBubble: some View {
        Text("\(item.content)\(invisibleSpaceForTime)")
            .font(.system(.headline, design: .rounded, weight: .regular))
            .foregroundColor(textColor)
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .frame(minWidth: Layout.minBubbleWidth, minHeight: Layout.minBubbleHeight, alignment: .leading)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: Layout.bubbleCornerRadius))
            .overlay(
                Text(item.date)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .foregroundColor(textColor.opacity(0.5))
                    .padding(.trailing, 13)
                    .padding(.bottom, 9),
                alignment: .bottomTrailing
            )
    }

    /// Reserves the timestamp width so the bubble does not grow when the time appears.
    private var invisibleSpaceForTime: Text {
        Text("\u{00A0}\u{00A0}" + item.date)
            .font(.system(.footnote, design: .rounded, weight: .regular))
            .foregroundColor(.clear)
    }
}
