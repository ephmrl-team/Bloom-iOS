//
//  SettingsView.swift
//  Bloom
//
//  Created by Аскольд on 13.08.2026.
//

import SwiftUI

struct SettingsView: View {
    var allowsDismiss = true

    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(BloomManager.self) private var bloomManager

    var body: some View {
        List {
            Section {
                Button(role: .destructive) {
                    bloomManager.logout()

                    if allowsDismiss {
                        router.dismissModal()
                    }

                    appState.logout()
                } label: {
                    Label("Log Out", systemImage: "arrow.left.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollEdgeEffectHidden(true, for: .all)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(bloomManager.currentUser?.displayName ?? bloomManager.currentUser?.username ?? "Settings")
                    .font(.system(.headline, design: .rounded))
            }
            if allowsDismiss {
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
        }
        .topVariableBlur()
        .bottomSafeAreaGradient()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(Router())
    .environment(AppState())
    .environment(BloomManager(backend: MockAPI()))
}
#endif
