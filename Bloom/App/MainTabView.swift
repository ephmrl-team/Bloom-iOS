//
//  MainTabView.swift
//  Bloom
//

import SwiftUI
import UIKit

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
                tabIcon("saved.flag", label: "Saved")
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
                tabIcon("chat.bubbles", label: "Chats")
            }
            .tag(Tab.chats)

            NavigationStack {
                SettingsView(allowsDismiss: false)
            }
            .tabItem {
                tabIcon("gear", label: "Settings")
            }
            .tag(Tab.settings)
        }
        .tint(.primary)
    }

    /// Icons only, 32 pt: the tab bar carries no labels.
    private func tabIcon(_ name: String, label: LocalizedStringKey) -> some View {
        Image(uiImage: Self.tabImage(name))
            .accessibilityLabel(label)
    }

    /// A tab item draws its image at the natural size, so the icon is rendered at 32 pt first.
    private static func tabImage(_ name: String) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            UIImage(named: name)?.draw(in: CGRect(origin: .zero, size: size))
        }
        return image.withRenderingMode(.alwaysTemplate)
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
