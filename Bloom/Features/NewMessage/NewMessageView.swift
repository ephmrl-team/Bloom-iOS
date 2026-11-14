//
//  NewMessageView.swift
//  Bloom
//

import SwiftUI

struct NewMessageView: View {
    @Environment(Router.self) private var router
    @Environment(BloomManager.self) private var bloomManager

    @State private var searchText = ""
    @State private var users: [User] = []

    var body: some View {
        NavigationStack {
            List(users, id: \.id) { user in
                NewMessageRowView(user: user) {
                    openChat(with: user)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollEdgeEffectHidden(true, for: .all)
            .searchable(text: $searchText, placement: .navigationBarDrawer)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New message")
                        .font(.system(.headline, design: .rounded))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        router.dismissModal()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .controlSize(.regular)
                }
            }
            .topVariableBlur()
            .bottomSafeAreaGradient()
            .task(id: searchText) {
                await search()
            }
        }
        .heroNavigationTransition(id: "newMessageButton")
    }

    private func search() async {
        if !searchText.isEmpty {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
        }

        users = await bloomManager.searchUsers(searchText)
    }

    private func openChat(with user: User) {
        Task {
            guard let chatID = await bloomManager.openChat(with: user) else { return }
            router.selectChat(id: chatID)
        }
    }
}

#Preview {
    NewMessageView()
        .environment(Router())
}
