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
    let profileZoom: Namespace.ID

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            ChatViewToolbarUser(chat: chat, profileZoom: profileZoom)
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
    let profileZoom: Namespace.ID

    @Environment(KeyboardTracker.self) private var keyboard
    @Environment(Router.self) private var router

    private var name: String {
        chat?.title ?? chat?.recipient?.displayName ?? chat?.recipient?.username ?? "Chat"
    }

    private var avatarID: String {
        chat?.recipient?.id ?? String(chat?.id ?? 0)
    }

    var body: some View {
        Button {
            keyboard.dismiss()
            router.push(.profile(id: avatarID))
        } label: {
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
                image: chat?.recipient?.avatarUrl,
                id: avatarID,
                name: name
            )
            .matchedTransitionSource(id: avatarID, in: profileZoom)

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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
