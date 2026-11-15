//
//  MainTabView.swift
//  Bloom
//

import SwiftUI

struct MainTabView: View {
    private enum Tab: Hashable {
        case saved
        case chats
        case settings
    }

    @Environment(Router.self) private var router

    @State private var selection: Tab = .chats

    var body: some View {
        @Bindable var router = router

        TabView(selection: $selection) {
            NavigationStack {
                SavedMessagesView()
            }
            .tabItem {
                Label("Saved", image: "saved.flag")
            }
            .tag(Tab.saved)

            NavigationStack(path: $router.path) {
                ChatListView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .chatList:
                            ChatListView()
                        case .chat(let id):
                            ChatView(chatId: id)
                        case .profile(let id):
                            ProfileView(userID: id)
                        }
                    }
            }
            .tabItem {
                Label("Chats", image: "chat.bubbles")
            }
            .tag(Tab.chats)

            NavigationStack {
                SettingsView(allowsDismiss: false)
            }
            .tabItem {
                Label("Settings", image: "gear")
            }
            .tag(Tab.settings)
        }
        .tint(.primary)
    }
}

#if DEBUG
#Preview {
    MainTabView()
        .environment(Router())
        .environment(AppState())
        .environment(BloomManager(backend: MockAPI()))
}
#endif
