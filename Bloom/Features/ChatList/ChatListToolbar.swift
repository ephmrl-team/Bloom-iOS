//
//  ChatListToolbar.swift
//  Bloom
//
//  Created by Аскольд on 12.08.2026.
//

import SwiftUI


struct ChatListToolbar: ToolbarContent {
    let logoRotation: Double
    
    @Environment(Router.self) private var router
    @Environment(BloomManager.self) private var bloomManager
    
    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: Theme.spacing.sm) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 19, height: 19)
                            .rotationEffect(.degrees(logoRotation))

                        Text("Bloom")
                            .foregroundColor(.primary)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }
                    .fixedSize(horizontal: true, vertical: false)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                router.presentModal(.settings)
            } label: {
                AvatarView(
                    size: .md,
                    square: false,
                    id: bloomManager.currentUser?.id ?? "",
                    name: bloomManager.currentUser?.displayName ?? bloomManager.currentUser?.username ?? "You"
                )
            }
            .buttonStyle(.plain)
            .controlSize(.regular)
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("settingsButton")
            .glassEffect(.regular.interactive())
        }
        .sharedBackgroundVisibility(.hidden)

        DefaultToolbarItem(kind: .search, placement: .bottomBar)

        ToolbarSpacer(.fixed, placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
            Button {
                router.presentModal(.newMessage)
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .controlSize(.large)
            .accessibilityLabel("New message")
            .accessibilityIdentifier("newMessageButton")
            .heroTransitionSource(id: "newMessageButton")
        }
    }
}
