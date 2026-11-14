//
//  ChatViewToolbar.swift
//  Bloom
//
//  Created by Аскольд on 12.08.2026.
//

import SwiftUI

struct ChatViewToolbar: ToolbarContent {
    let chat: ChatResponse?

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            ChatViewToolbarUser(chat: chat)
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
    let chat: ChatResponse?

    private var name: String {
        chat?.title ?? chat?.recipient?.displayName ?? chat?.recipient?.username ?? "Chat"
    }

    private var avatarID: String {
        chat?.recipient?.id ?? String(chat?.id ?? 0)
    }

    var body: some View {
        NavigationLink(value: Route.profile(id: avatarID)) {
            content
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Chat profile: \(name)")
        .accessibilityIdentifier("chatProfileButton")
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
        }
    }
}
