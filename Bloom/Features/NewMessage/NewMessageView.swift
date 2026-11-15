//
//  NewMessageView.swift
//  Bloom
//

import SwiftUI
import OSLog

struct NewMessageView: View {
    @Environment(Router.self) private var router
    @Environment(BloomManager.self) private var bloomManager

    @State private var searchText = ""
    @State private var users: [User] = []
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            content
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
                            Image("x.mark")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(.primary)
                        }
                        .controlSize(.regular)
                        .accessibilityLabel("Close")
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

    @ViewBuilder
    private var content: some View {
        if loadFailed {
            ContentUnavailableView {
                Label("Couldn't load people", systemImage: "wifi.exclamationmark")
            } description: {
                Text("Check your connection and try again.")
            } actions: {
                Button("Try again") {
                    Task { await search() }
                }
            }
        } else if users.isEmpty && !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
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
        }
    }

    private func search() async {
        if !searchText.isEmpty {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
        }

        do {
            users = try await bloomManager.searchUsers(searchText)
            loadFailed = false
        } catch {
            guard !Task.isCancelled else { return }
            Logger.bloom.error("user search failed: \(error, privacy: .public)")
            loadFailed = true
        }
    }

    private func openChat(with user: User) {
        Task {
            guard let chatID = await bloomManager.openChat(with: user) else { return }
            router.selectChat(id: chatID)
        }
    }
}

#if DEBUG
#Preview {
    NewMessageView()
        .environment(Router())
        .environment(BloomManager(backend: MockAPI()))
}
#endif
