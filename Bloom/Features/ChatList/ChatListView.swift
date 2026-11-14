//
//  ChatListView.swift
//  Bloom
//
//  Created by Аскольд on 10.08.2026.
//

import SwiftUI
import BlurSwiftUI
import BlurUIKit

struct ChatListView: View {
    var namespace: Namespace.ID
    
    @Environment(Router.self) private var router
    @Environment(BloomManager.self) private var bloomManager
    @State private var searchText = ""
    @State private var logoRotation: Double = 0

    var body: some View {
        List {
            ForEach(bloomManager.conversations, id: \.id) { chat in
                ChatsListRowView(chat: chat)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .onScrollGeometryChange(for: Double.self) { geometry in
            max(0, -(geometry.contentOffset.y + geometry.contentInsets.top) / 3)
        } action: { _, newValue in
            logoRotation = newValue
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollEdgeEffectHidden(true, for: .all)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .searchable(text: $searchText)
        .toolbarBackground(.hidden, for: .bottomBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ChatListToolbar(logoRotation: logoRotation)
        }
        .topVariableBlur()
        .bottomSafeAreaGradient()
    }
}
