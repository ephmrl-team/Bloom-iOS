//
//  ChatView.swift
//  Bloom
//

import SwiftUI

struct ChatView: View {
    let chatId: Int
    let profileZoom: Namespace.ID

    @Environment(BloomManager.self) private var bloomManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store: MessagesStore?
    @State private var keyboard = KeyboardTracker()
    @State private var toolbarIdealWidth: CGFloat = 0
    @State private var isAtBottom = true
    @State private var bottomSpacerID = UUID()

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
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { keyboard.update(safeAreaBottom: $0) }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ChatViewToolbar(chat: chat, idealWidth: toolbarIdealWidth, profileZoom: profileZoom)
        }
        .environment(keyboard)
        .background {
            KeyboardTrackerHost(tracker: keyboard)
        }
        .bottomSafeAreaGradient()
        .topVariableBlur()
        .simultaneousGesture(
            DragGesture(minimumDistance: 3).onChanged { _ in keyboard.dismiss() }
        )
        .onDisappear { keyboard.dismiss() }
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
        // Read once so a seen-marker update does not invalidate every row.
        let seenID = store.lastSeenId

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.data, id: \.renderID) { item in
                        ChatRowView(item: item, isSeen: item.id > 0 && item.id <= seenID)
                            .equatable()
                            .padding(.horizontal, Theme.spacing.lg)
                            .id(item.renderID)
                            .transition(.asymmetric(
                                insertion: .opacity
                                    .combined(with: .blur(radius: reduceMotion ? 0 : 10))
                                    .combined(with: .offset(y: reduceMotion ? 0 : 150)),
                                removal: .opacity
                            ))
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomSpacerID)
                }
            }
            .onChange(of: store.data.count) { oldCount, newCount in
                guard newCount > oldCount, isAtBottom || store.data.last?.me == true else { return }
                // The first batch is placed by the bottom anchor; animating it would look like a scroll.
                guard oldCount > 0 else {
                    proxy.scrollTo(bottomSpacerID, anchor: .bottom)
                    return
                }
                withAnimation(.smooth(duration: 0.235)) {
                    proxy.scrollTo(bottomSpacerID, anchor: .bottom)
                }
            }
        }
        .opacity(store.data.isEmpty ? 0 : 1)
        .accessibilityIdentifier("chatMessageList")
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.bottom)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y >= geometry.contentSize.height - geometry.containerSize.height - 120
        } action: { _, atBottom in
            isAtBottom = atBottom
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatComposerInset()
                .disabled(store.data.isEmpty && (store.isLoading || store.loadFailed))
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .scrollDismissesKeyboard(.immediately)
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
            .padding(.bottom, KeyboardTracker.bottomInset(for: keyboard.progress))
    }
}
