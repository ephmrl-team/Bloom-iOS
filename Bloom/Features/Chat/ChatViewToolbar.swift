//
//  ChatViewToolbar.swift
//  Bloom
//
//  Created by Аскольд on 12.08.2026.
//

import SwiftUI

struct ChatViewToolbar: ToolbarContent {
    let chatId: Int

    @Environment(Router.self) private var router

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            ChatViewToolbarUser(chatId: chatId, isPreview: false)
            .fixedSize(horizontal: true, vertical: false)

        }
        .sharedBackgroundVisibility(.hidden)

        ToolbarSpacer(.flexible, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
            ChatViewToolbarMenu()
        }
    }
}

struct ChatViewToolbarUser: View {
    let chatId: Int
    let isPreview: Bool

    @Environment(BloomManager.self) private var bloomManager

    private var chat: ChatResponse? {
        bloomManager.conversations.first { $0.id == chatId }
    }

    private var name: String {
        chat?.title ?? chat?.recipient?.displayName ?? chat?.recipient?.username ?? "Chat"
    }

    private var avatarID: String {
        chat?.recipient?.id ?? String(chatId)
    }

    var body: some View {
        if isPreview {
            content
        } else {
            NavigationLink(value: Route.profile(id: avatarID)) {
                content
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Chat profile: \(name)")
            .accessibilityIdentifier("chatProfileButton")
        }
    }

    private var content: some View {
        HStack(spacing: Theme.spacing.md) {
            AvatarView(
                size: .md,
                id: avatarID,
                name: name
            )

            VStack(alignment: .center, spacing: Theme.spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.spacing.xs) {
                    Text(name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: Theme.spacing.xs)
                }

                HStack(alignment: .firstTextBaseline, spacing: Theme.spacing.xs) {
                    Text("Last seen recently")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)

                    Spacer(minLength: Theme.spacing.xs)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: isPreview ? nil : .infinity, alignment: .center)
        }
    }
}
