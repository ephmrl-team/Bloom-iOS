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

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        if isSearching {
            ToolbarItem(placement: .principal) {
                ChatSearchField(text: $searchText, isSearching: $isSearching)
                    // The toolbar sizes an item to its ideal width, so the field asks for the whole bar.
                    .frame(minWidth: 0, idealWidth: 10_000, maxWidth: .infinity)
                    .frame(height: 44)
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                searchButton
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
                .foregroundStyle(Theme.colors.secondaryText)
        }
        .buttonStyle(GlassCircleButtonStyle())
        .accessibilityLabel("Search")
        .accessibilityIdentifier("searchButton")
    }

    private var composerButton: some View {
        Button {
            router.presentModal(.newMessage)
        } label: {
            toolbarIcon("square.and.pencil", size: 28)
                .foregroundStyle(.white)
        }
        .buttonStyle(GlassCircleButtonStyle(tint: Theme.colors.primary))
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

/// Draws the glass inside the button, so the button itself is the only control.
private struct GlassCircleButtonStyle: ButtonStyle {
    var tint: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .glassEffect(.regular.tint(tint).interactive(), in: Circle())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
