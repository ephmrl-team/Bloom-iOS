//
//  ChatView.swift
//  Bloom
//

import SkulletX
import SwiftUI

struct ChatView: View {
    let chatId: Int
    let profileZoom: Namespace.ID

    @Environment(BloomManager.self) private var bloomManager
    @State private var store: MessagesStore?
    @State private var keyboard = KeyboardTracker()
    @State private var contextMenu = ChatContextMenuModel()
    @State private var toolbarIdealWidth: CGFloat = 0
    @State private var topInset: CGFloat = 0
    @State private var isAtBottom = true
    @State private var listReady = false
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
        .environment(contextMenu)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            toolbarIdealWidth = width
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: {
            keyboard.update(safeAreaBottom: $0)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: {
            topInset = $0
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ChatViewToolbar(chat: chat, idealWidth: toolbarIdealWidth, profileZoom: profileZoom)
        }
        .environment(keyboard)
        .background {
            KeyboardTrackerHost(tracker: keyboard)
        }
        .onChange(of: contextMenu.liftedRenderID) { _, id in
            if id == nil {
                keyboard.resumeAfterContextMenu()
            }
        }
        .bottomSafeAreaGradient()
        .topVariableBlur()
        .onDisappear {
            keyboard.dismiss()
            keyboard.resetContextMenuLock()
            contextMenu.dismissImmediately()
        }
        .task {
            guard store == nil else { return }
            let store = bloomManager.makeMessagesStore(chatID: chatId)
            self.store = store
            await store.load()
        }
    }

    private func content(_ store: MessagesStore) -> some View {
        messages(store)
            .overlay {
                if store.data.isEmpty, !store.isLoading {
                    if store.loadFailed {
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

        return bottomTracking(messageScroll(store, seenID: seenID), store)
            .opacity(listReady ? 1 : 0)
            .skulletReveal(isLoading: store.data.isEmpty && store.isLoading) {
                ChatMessagesSkeleton()
            }
            // The sweep mask has to cover the header, so the pane ignores the top inset and the
            // scroll view puts it back as content margin.
            .ignoresSafeArea(.container, edges: .top)
            .accessibilityIdentifier("chatMessageList")
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.bottom)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ChatComposerInset()
                    .disabled(store.data.isEmpty && (store.isLoading || store.loadFailed))
            }
            .ignoresSafeArea(.container, edges: .bottom)
            // Dismissed through the tracker so the keyboard hides with the composer animation; the
            // `.scrollDismissesKeyboard` modes drop it without that animation.
            .onScrollPhaseChange { _, phase in
                if phase == .interacting {
                    keyboard.dismiss()
                }
            }
            // The system edge effect is replaced by `topVariableBlur()` on the screen.
            .scrollEdgeEffectHidden(true, for: .top)
    }

    private func bottomTracking(_ view: some View, _ store: MessagesStore) -> some View {
        view.onScrollGeometryChange(for: Bool.self) { geometry in
            // The keyboard sits in the content inset, so the offset alone never reports the bottom.
            geometry.contentOffset.y + geometry.contentInsets.bottom
                >= geometry.contentSize.height - geometry.containerSize.height - 120
        } action: { _, atBottom in
            isAtBottom = atBottom
            if atBottom, !store.data.isEmpty {
                listReady = true
            }
        }
    }

    private func messageScroll(_ store: MessagesStore, seenID: Int) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.data, id: \.renderID) { item in
                        messageRow(item, seenID: seenID, store: store)
                    }

                    ChatMessageKeyboardHold()

                    Color.clear
                        .frame(height: 1)
                        .id(bottomSpacerID)
                }
                .padding(.top, topInset)
            }
            // Anchored here too: after a push the outer anchor can land before the inset settles.
            .defaultScrollAnchor(.bottom)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.bottom } action: { _, inset in
                keyboard.update(contentBottomInset: inset)
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                keyboard.update(scrollFrame: frame)
            }
            .onChange(of: store.data.count) { oldCount, newCount in
                scrollOnNewMessages(proxy: proxy, store: store, oldCount: oldCount, newCount: newCount)
            }
        }
    }

    private func scrollOnNewMessages(
        proxy: ScrollViewProxy,
        store: MessagesStore,
        oldCount: Int,
        newCount: Int
    ) {
        guard newCount > oldCount, isAtBottom || store.data.last?.me == true else { return }
        // The first batch is placed by the bottom anchor; scrolling to it would read as a jump.
        guard oldCount > 0 else {
            listReady = true
            return
        }
        withAnimation(.smooth(duration: 0.235)) {
            proxy.scrollTo(bottomSpacerID, anchor: .bottom)
        }
    }

    private func messageRow(_ item: MessageItem, seenID: Int, store: MessagesStore) -> some View {
        ChatMessageAppearance(
            item: item,
            isSeen: item.id > 0 && item.id <= seenID,
            animate: store.appearingMessageIDs.contains(item.renderID)
        ) {
            store.didShowMessage(item.renderID)
        }
        .id(item.renderID)
    }
}

/// Keeps the messages in place while the chat menu holds the keyboard's room in the content.
private struct ChatMessageKeyboardHold: View {
    @Environment(KeyboardTracker.self) private var keyboard

    var body: some View {
        Color.clear
            .frame(height: keyboard.frozenMessageBottomPadding)
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
