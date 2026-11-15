//
//  ChatListToolbar.swift
//  Bloom
//
//  Created by Аскольд on 12.08.2026.
//

import SwiftUI

struct ChatListToolbar: ToolbarContent {
    @Environment(Router.self) private var router

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: Theme.spacing.sm) {
                toolbarIcon("logo")
                    .foregroundStyle(Theme.colors.primary)

                Text("Chats")
                    .font(.system(.headline, design: .rounded, weight: .bold))
            }
            .fixedSize(horizontal: true, vertical: false)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                router.presentModal(.newMessage)
            } label: {
                toolbarIcon("square.and.pencil")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.colors.primary)
            .accessibilityLabel("New message")
            .accessibilityIdentifier("newMessageButton")
            .heroTransitionSource(id: "newMessageButton")
        }
    }

    private func toolbarIcon(_ name: String) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
    }
}
