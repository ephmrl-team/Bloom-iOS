//
//  ChatView.swift
//  Bloom
//

import SwiftUI

struct ChatView: View {
    let chatId: Int

    @Environment(BloomManager.self) private var bloomManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store: MessagesStore?
    @State private var keyboard = KeyboardTracker()
    @State private var toolbarIdealWidth: CGFloat = 0

    private var chat: ChatResponse? {
        bloomManager.conversations.first { $0.id == chatId }
    }

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
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            toolbarIdealWidth = width
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ChatViewToolbar(chat: chat, idealWidth: toolbarIdealWidth)
        }
        .environment(keyboard)
        .background {
            KeyboardTrackerHost(tracker: keyboard)
        }
        .bottomSafeAreaGradient()
        .topVariableBlur()
        .task {
            guard store == nil else { return }
            let store = bloomManager.makeMessagesStore(chatID: chatId)
            self.store = store
            await store.load()
        }
    }

    @ViewBuilder
    private func content(_ store: MessagesStore) -> some View {
        messages(store)
            .overlay {
                if store.data.isEmpty {
                    if store.isLoading {
                        ProgressView()
                    } else if store.loadFailed {
                        ContentUnavailableView {
                            Label("Couldn't load messages", systemImage: "exclamationmark.bubble")
                        } description: {
                            Text("Check your connection and try again.")
                        } actions: {
                            Button("Try again") {
                                Task { await store.load() }
                            }
                        }
                    } else {
                        ContentUnavailableView("No messages yet", systemImage: "bubble.left")
                    }
                }
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
                                .combined(with: .blur(radius: reduceMotion ? 0 : 10))
                                .combined(with: .offset(y: reduceMotion ? 0 : 30)),
                            removal: .opacity
                        ))
                }
            }
        }
        .accessibilityIdentifier("chatMessageList")
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatComposerInset()
                .disabled(store.data.isEmpty && (store.isLoading || store.loadFailed))
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .scrollDismissesKeyboard(.interactively)
        // The system edge effect is replaced by `topVariableBlur()` on the screen.
        .scrollEdgeEffectHidden(true, for: .top)
    }
}

/// Owns the per-frame keyboard geometry so the composer's own body stays out of it.
private struct ChatComposerInset: View {
    @Environment(KeyboardTracker.self) private var keyboard
    var body: some View {
        ChatFooterView()
            .padding(.horizontal, KeyboardTracker.padding(for: keyboard.progress))
            .padding(.top, Theme.spacing.md)
            .padding(.bottom, KeyboardTracker.padding(for: keyboard.progress))
    }
}
