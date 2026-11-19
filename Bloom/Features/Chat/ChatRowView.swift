//
//  ChatRowView.swift
//  Bloom
//
// Created by Аскольд on 13.08.2026.
//

import SwiftUI

struct ChatRowView: View, Equatable {
    let item: MessageItem
    let isSeen: Bool
    var isLifted = false

    var onCopy: (Int) -> Void = { _ in }
    var onReply: (Int) -> Void = { _ in }
    var onForward: (Int) -> Void = { _ in }
    var onDelete: (Int) -> Void = { _ in }

    static func == (lhs: ChatRowView, rhs: ChatRowView) -> Bool {
        lhs.item == rhs.item && lhs.isSeen == rhs.isSeen && lhs.isLifted == rhs.isLifted
    }

    private enum Layout {
        static let sideSpacer: CGFloat = 55
    }

    private var actions: ChatMenuActions {
        var menu = ChatMenuActions()
        menu.copy = { onCopy(item.id) }
        menu.reply = { onReply(item.id) }
        menu.forward = { onForward(item.id) }
        if item.me {
            menu.delete = { onDelete(item.id) }
        }
        return menu
    }

    var body: some View {
        HStack {
            if item.me {
                Spacer(minLength: Layout.sideSpacer)
            }

            VStack(alignment: item.me ? .trailing : .leading, spacing: 0) {
                ChatBubbleContent(item: item)
                    .chatBubbleLift(item: item, isLifted: isLifted, actions: actions)

                if item.me {
                    readReceipt
                }
            }
            .padding(.top, Theme.spacing.lg)

            if !item.me {
                Spacer(minLength: Layout.sideSpacer)
            }
        }
        .contentShape(.rect)
    }

    private var readReceipt: some View {
        Text("Read")
            .font(.system(.subheadline, design: .rounded, weight: .regular))
            .foregroundColor(.secondary)
            .padding(.top, isSeen ? Theme.spacing.sm : 0)
            .frame(height: isSeen ? nil : 0, alignment: .top)
            .opacity(isSeen ? 1 : 0)
    }
}
