//
//  SettingsRowLink.swift
//  Bloom
//

import SwiftUI

/// Mirrors `ChatsListRowView`: the invisible link in the background navigates without leaving
/// the row stuck in a selected state after the destination is popped.
struct SettingsRowLink<Content: View>: View {
    let route: SettingsRoute
    @ViewBuilder var content: Content

    var body: some View {
        content
            .contentShape(.rect)
            .background {
                NavigationLink(value: route) {
                    EmptyView()
                }
                .opacity(0)
            }
            .buttonStyle(.plain)
    }
}
