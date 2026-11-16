//
//  ChatListToolbar.swift
//  Bloom
//

import SwiftUI

struct ChatListToolbar: ToolbarContent {
    @Environment(Router.self) private var router
    @Environment(BloomManager.self) private var bloomManager
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.presentModal(.newMessage)
            } label: {
                Image("square.and.pencil")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
            .tint(.primary)
            .accessibilityLabel("New message")
            .accessibilityIdentifier("newMessageButton")
        }

        ToolbarItem(placement: .principal) {
            ChatListTitle(state: ChatListTitleState(
                isOnline: networkMonitor.isOnline,
                hasLoadedChats: bloomManager.hasLoadedChats,
                hasError: bloomManager.hasChatListError
            ))
        }
    }
}
