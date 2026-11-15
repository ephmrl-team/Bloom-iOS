//
//  ContentView.swift
//  Bloom
//
//  Created by Аскольд on 10.08.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var router = Router()
    @Namespace private var heroNamespace

    var body: some View {
        MainTabView()
            .sheet(item: $router.presentedSheet, onDismiss: {
                router.pushPendingRouteIfNeeded()
            }) { modal in
                switch modal {
                case .newMessage:
                    NewMessageView()
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.hidden)
                case .settings:
                    NavigationStack {
                        SettingsView()
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                }
            }
            .environment(router)
            .environment(\.heroNamespace, heroNamespace)
            .onAppear {
                router.pushPendingRouteIfNeeded()
            }
    }
}
