//
//  ChatListRowPreviewView.swift
//  Bloom
//

import SwiftUI
import BlurSwiftUI
import BlurUIKit

/// Uses an isolated store because the preview is hosted outside the app's environment.
struct ChatPreviewView: View {
    let chat: ChatResponse
    let store: MessagesStore
    let width: CGFloat

    private var name: String {
        chat.recipient?.displayName ?? chat.recipient?.username ?? chat.title ?? "Chat"
    }

    private var avatarID: String {
        chat.recipient?.id ?? String(chat.id)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.data, id: \.renderID) { item in
                        ChatRowView(item: item, isSeen: item.id > 0 && item.id <= store.lastSeenId)
                            .padding(.horizontal, Theme.spacing.lg)
                    }
                }
                .padding(.top, 68)
                .padding(.bottom, Theme.spacing.lg)
            }
            .defaultScrollAnchor(.bottom)
            .scrollIndicators(.hidden)
            .allowsHitTesting(false)
            .overlay {
                if store.isLoading {
                    ProgressView()
                } else if store.loadFailed {
                    Text("Couldn't load messages")
                } else if store.data.isEmpty {
                    Text("No messages yet")
                }
            }

            header
        }
        .frame(width: width, height: 480)
        .background(Theme.colors.background)
        .task { await store.load() }
    }

    private var header: some View {
        ZStack(alignment: .top) {
            VariableBlurView(height: 76, color: Theme.colors.background)

            HStack(spacing: Theme.spacing.md) {
                AvatarView(size: .md, id: avatarID, name: name)

                VStack(alignment: .leading, spacing: Theme.spacing.xs) {
                    Text(name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("Last seen recently")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.spacing.lg)
            .padding(.top, Theme.spacing.md)
            .padding(.bottom, Theme.spacing.md)
        }
    }
}
