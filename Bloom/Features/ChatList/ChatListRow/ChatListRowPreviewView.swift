//
//  ChatListRowPreviewView.swift
//  Bloom
//

import SwiftUI
import BlurSwiftUI
import BlurUIKit

/// Static snapshot for the long-press preview. It deliberately avoids the live chat
/// stack (`ChatRowView`, `MessagesStore`, environment lookups): a context-menu preview
/// is hosted outside the app's environment and crashes when it depends on it.
struct ChatPreviewView: View {
    let chat: ChatResponse

    private var name: String {
        chat.recipient?.displayName ?? chat.recipient?.username ?? chat.title ?? "Chat"
    }

    private var avatarID: String {
        chat.recipient?.id ?? String(chat.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                VariableBlurView(height: 76, color: Theme.colors.background)

                HStack(spacing: Theme.spacing.md) {
                    AvatarView(size: .md, id: avatarID, name: name)

                    VStack(alignment: .leading, spacing: Theme.spacing.xs) {
                        Text(name)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("Last seen recently")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(Theme.spacing.lg)
            }

            Spacer(minLength: 0)

            Text(chat.lastMessage?.content ?? "No messages")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.colors.text)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .padding(Theme.spacing.md)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .padding(.horizontal, Theme.spacing.lg)
                .padding(.bottom, Theme.spacing.lg)
        }
        .frame(width: 320, height: 480)
        .background(Theme.colors.background)
    }
}
