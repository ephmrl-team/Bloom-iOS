//
//  ChatListToolbar.swift
//  Bloom
//

import SwiftUI

struct ChatListToolbar: ToolbarContent {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Environment(Router.self) private var router
    @Environment(BloomManager.self) private var bloomManager
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Namespace private var searchNamespace

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        if isSearching {
            ToolbarItem(placement: .principal) {
                ChatSearchField(text: $searchText)
                    // The toolbar sizes an item to its ideal width, so the field asks for the whole bar.
                    .frame(minWidth: 0, idealWidth: 10_000, maxWidth: .infinity)
                    .frame(height: 44)
                    .matchedGeometryEffect(id: "search", in: searchNamespace)
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                searchButton
                    .matchedGeometryEffect(id: "search", in: searchNamespace)
            }

            ToolbarItem(placement: .principal) {
                ChatListTitle(state: titleState)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            composerButton
        }
    }

    private var titleState: ChatListTitleState {
        ChatListTitleState(
            isOnline: networkMonitor.isOnline,
            hasLoadedChats: bloomManager.hasLoadedChats,
            hasError: bloomManager.hasChatListError
        )
    }

    private var searchButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.3)) {
                isSearching = true
            }
        } label: {
            toolbarIcon("magnifyingglass", size: 28)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("Search")
        .accessibilityIdentifier("searchButton")
    }

    private var composerButton: some View {
        Button(action: composerAction) {
            if isSearching {
                toolbarIcon("x.mark", size: 24)
                    .foregroundStyle(.white)
            } else {
                toolbarIcon("square.and.pencil", size: 28)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(isSearching ? Theme.colors.secondaryText : Theme.colors.primary)
        .frame(width: 44, height: 44)
        .accessibilityLabel(isSearching ? "Close search" : "New message")
        .accessibilityIdentifier(isSearching ? "searchCloseButton" : "newMessageButton")
    }

    private func composerAction() {
        if isSearching {
            withAnimation(.smooth(duration: 0.3)) {
                searchText = ""
                isSearching = false
            }
        } else {
            router.presentModal(.newMessage)
        }
    }

    private func toolbarIcon(_ name: String, size: CGFloat) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
