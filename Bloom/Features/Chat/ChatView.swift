//
// ChatView.swift
// Bloom
//
// Created by Аскольд on 11.08.2026.
//

import SwiftUI
import BlurSwiftUI
import BlurUIKit

struct ChatView: View {
    let chatId: Int

    @Environment(MessagesStore.self) private var store

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.data) { item in
                    ChatRowView(
                        item: item,
                        isSeen: item.id <= store.lastSeenId
                    )
                    .equatable()
                    .padding(.horizontal, Theme.spacing.lg)
                    .transition(.asymmetric(
                        insertion: AnyTransition.opacity
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ChatViewToolbar(chatId: chatId)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .topVariableBlur()
        .bottomSafeAreaGradient()
    }
}
