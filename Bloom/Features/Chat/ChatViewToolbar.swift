//
//  ChatViewToolbar.swift
//  Bloom
//
//  Created by Аскольд on 12.08.2026.
//

import SwiftUI

struct ChatViewToolbar: ToolbarContent {
    let chat: ChatResponse?
    let idealWidth: CGFloat

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            ChatViewToolbarUser(chat: chat)
                .frame(minWidth: 0, idealWidth: idealWidth, maxWidth: .infinity, alignment: .leading)
        }
        .sharedBackgroundVisibility(.hidden)

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                // shortcut: no chat actions yet, wire the options menu here when they exist
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .tint(.primary)
            .accessibilityLabel("Chat options")
            .accessibilityIdentifier("chatOptionsButton")
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
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

            VStack(alignment: .leading, spacing: Theme.spacing.micro) {
                Text(name)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("Last seen recently")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
