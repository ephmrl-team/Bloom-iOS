//
//  ChatListToolbar.swift
//  Bloom
//
//  Created by Аскольд on 12.08.2026.
//

import SwiftUI

struct ChatListToolbar: ToolbarContent {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Environment(Router.self) private var router
    @Environment(BloomManager.self) private var bloomManager
    @Environment(NetworkMonitor.self) private var networkMonitor

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        if isSearching {
            ToolbarItem(placement: .principal) {
                ChatSearchField(text: $searchText)
                    // The toolbar sizes an item to its ideal width, so the field asks for the whole bar.
                    .frame(minWidth: 0, idealWidth: 10_000, maxWidth: .infinity)
                    .frame(height: 44)

            }

            ToolbarItem(placement: .topBarTrailing) {
                closeSearchButton
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                searchButton
            }

            ToolbarItem(placement: .principal) {
                title
            }

            ToolbarItem(placement: .topBarTrailing) {
                composerButton
            }
        }
    }

    private var title: some View {
        ChatListTitle(
            state: ChatListTitleState(
                isOnline: networkMonitor.isOnline,
                hasLoadedChats: bloomManager.hasLoadedChats,
                hasError: bloomManager.hasChatListError
            )
        )
    }

    private var searchButton: some View {
        Button {
            isSearching = true
        } label: {
            toolbarIcon("magnifyingglass", size: 28)
        }
        .accessibilityLabel("Search")
        .accessibilityIdentifier("searchButton")
    }

    private var closeSearchButton: some View {
        Button {
            searchText = ""
            isSearching = false
        } label: {
            toolbarIcon("x.mark", size: 28)
        }
        .accessibilityLabel("Close search")
        .accessibilityIdentifier("searchCloseButton")
    }

    private var composerButton: some View {
        Button {
            router.presentModal(.newMessage)
        } label: {
            toolbarIcon("square.and.pencil", size: 28)
                .foregroundStyle(.white)
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.colors.primary)
        .accessibilityLabel("New message")
        .accessibilityIdentifier("newMessageButton")
    }

    private func toolbarIcon(_ name: String, size: CGFloat) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
