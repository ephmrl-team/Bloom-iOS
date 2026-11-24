//
//  ChatListTitle.swift
//  Bloom
//

import SwiftUI

/// What the chat list title says about the connection to the backend.
enum ChatListTitleState: Equatable {
    case online
    case connecting
    case offline
    case error

    /// Offline wins over an error, an error over a load that is still in flight.
    init(isOnline: Bool, hasLoadedChats: Bool, hasError: Bool) {
        if !isOnline {
            self = .offline
        } else if hasError {
            self = .error
        } else if !hasLoadedChats {
            self = .connecting
        } else {
            self = .online
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .online: "Chats"
        case .connecting: "Connecting…"
        case .offline: "No internet"
        case .error: "Connection error"
        }
    }

    var tint: Color {
        switch self {
        case .online: Theme.colors.primary
        case .connecting: Theme.colors.secondaryText
        case .offline: Theme.colors.orange
        case .error: Theme.colors.red
        }
    }
}

struct ChatListTitle: View {
    let state: ChatListTitleState

    var body: some View {
        HStack(spacing: Theme.chatListTitle.spacing) {
            Image("logo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Theme.chatListTitle.iconSize, height: Theme.chatListTitle.iconSize)
                .foregroundStyle(state.tint)

            Text(state.title)
                .font(.system(size: Theme.chatListTitle.fontSize, weight: .bold, design: .rounded))
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("chatListTitle")
    }
}

#Preview {
    VStack(spacing: Theme.spacing.lg) {
        ChatListTitle(state: .online)
        ChatListTitle(state: .connecting)
        ChatListTitle(state: .offline)
        ChatListTitle(state: .error)
    }
}
