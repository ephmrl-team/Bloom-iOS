//
//  ChatListHeader.swift
//  Bloom
//

import SwiftUI

/// The chat list header: the search control on the left, the title in the
/// middle and the composer on the right.
struct ChatListHeader: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let titleState: ChatListTitleState
    let onCompose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.spacing.md) {
            ChatSearchField(text: $searchText, isSearching: $isSearching)
            composerButton
        }
        .overlay {
            ChatListTitle(state: titleState)
                .opacity(isSearching ? 0 : 1)
                .allowsHitTesting(false)
                .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: isSearching)
        }
        .padding(.horizontal, Theme.spacing.lg)
        .padding(.vertical, Theme.spacing.sm)
    }

    private var composerButton: some View {
        Button(action: onCompose) {
            Image("square.and.pencil")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(.white)
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.colors.primary)
        .accessibilityLabel("New message")
        .accessibilityIdentifier("newMessageButton")
    }
}

#Preview {
    @Previewable @State var searchText = ""
    @Previewable @State var isSearching = false

    VStack(spacing: Theme.spacing.lg) {
        ChatListHeader(
            searchText: $searchText,
            isSearching: $isSearching,
            titleState: .online,
            onCompose: {}
        )

        Spacer()
    }
}
