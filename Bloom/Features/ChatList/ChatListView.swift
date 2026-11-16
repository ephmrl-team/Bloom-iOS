//
//  ChatListView.swift
//  Bloom
//
//  Created by Аскольд on 10.08.2026.
//

import SwiftUI

struct ChatListView: View {
    @Environment(Router.self) private var router
    @Environment(BloomManager.self) private var bloomManager
    @State private var searchText = ""

    private var visibleChats: [ChatResponse] {
        let query = searchText.trim().lowercased()
        guard !query.isEmpty else { return bloomManager.conversations }

        return bloomManager.conversations.filter { chat in
            let name = chat.recipient?.displayName ?? chat.recipient?.username ?? chat.title ?? ""
            return name.lowercased().contains(query)
        }
    }

    var body: some View {
        // The search field host must live outside `content`: swapping its branches would tear the
        // representable down, and dismantling it removes the search controller mid-typing.
        ZStack {
            content
            ChatSearchField(text: $searchText)
                .frame(width: 0, height: 0)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ChatListToolbar()
        }
        .topVariableBlur()
    }

    @ViewBuilder
    private var content: some View {
        if !visibleChats.isEmpty {
            chats
        } else if !searchText.trim().isEmpty && bloomManager.hasLoadedChats {
            ContentUnavailableView.search(text: searchText)
        } else if bloomManager.hasLoadedChats {
            emptyState
        } else {
            ProgressView()
        }
    }

    private var chats: some View {
        List {
            ForEach(visibleChats, id: \.id) { chat in
                ChatsListRowView(chat: chat)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .accessibilityIdentifier("chatRow_\(chat.id)")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .scrollEdgeEffectHidden(true, for: .all)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            VStack(spacing: Theme.spacing.md) {
                Text("🥲")
                    .font(.system(size: 64))

                Text("No chats here yet.")
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }
        } description: {
            Text("Start a chat: tap the button below → add or select a friend.")
        } actions: {
            Button("Start a new chat") {
                router.presentModal(.newMessage)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.colors.primary)
        }
    }
}
