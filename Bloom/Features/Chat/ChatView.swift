//
//  ChatView.swift
//  Bloom
//

import SwiftUI
import BlurSwiftUI
import BlurUIKit

struct ChatView: View {
    let chatId: Int

    @Environment(BloomManager.self) private var bloomManager
    @State private var store: MessagesStore?

    var body: some View {
        Group {
            if let store {
                content(store)
                    .environment(store)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ChatViewToolbar(chatId: chatId)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .topVariableBlur()
        .bottomSafeAreaGradient()
        .task {
            guard store == nil else { return }
            let store = bloomManager.makeMessagesStore(chatID: chatId)
            self.store = store
            await store.load()
        }
    }

    @ViewBuilder
    private func content(_ store: MessagesStore) -> some View {
        if store.isLoading && store.data.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.loadFailed && store.data.isEmpty {
            ContentUnavailableView {
                Label("Couldn't load messages", systemImage: "exclamationmark.bubble")
            } description: {
                Text("Check your connection and try again.")
            } actions: {
                Button("Try again") {
                    Task { await store.load() }
                }
            }
        } else if store.data.isEmpty {
            ContentUnavailableView("No messages yet", systemImage: "bubble.left")
        } else {
            messages(store)
        }
    }

    private func messages(_ store: MessagesStore) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.data) { item in
                    ChatRowView(item: item, isSeen: item.id <= store.lastSeenId)
                        .equatable()
                        .padding(.horizontal, Theme.spacing.lg)
                        .transition(.asymmetric(
                            insertion: .opacity
                                .combined(with: .blur(radius: 10))
                                .combined(with: .offset(y: 100)),
                            removal: .opacity
                        ))
                }
            }
        }
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatFooterView()
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .scrollDismissesKeyboard(.interactively)
        .scrollEdgeEffectHidden(true, for: .all)
    }
}
