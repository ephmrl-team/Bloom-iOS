//
//  ChatsListRowView.swift
//  Bloom
//
//  Created by Аскольд on 11.08.2026.
//

import SwiftUI

struct ChatsListRowView: View {
    let chat: ChatResponse
    @Environment(BloomManager.self) private var bloomManager
    @State private var previewWidth: CGFloat = 320

    private func formatTime(from timestamp: Int64?) -> String {
        guard let ts = timestamp else { return "" }
        return Date(timeIntervalSince1970: TimeInterval(ts))
            .formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }

    var body: some View {
        let recipientName = chat.recipient?.displayName ?? chat.recipient?.username ?? "Unknown"
        let lastMsgText = chat.lastMessage?.content ?? "No messages"
        let timeText = formatTime(from: chat.lastMessage?.timestamp)

        HStack(alignment: .top, spacing: 0) {
            AvatarView(
                size: .lg,
                id: chat.recipient?.id ?? String(chat.id),
                name: recipientName
            )
            .padding(.trailing, Theme.spacing.lg)
            .padding(.vertical, Theme.spacing.md)

            VStack(alignment: .center, spacing: Theme.spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.spacing.xs) {
                    Text(recipientName)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: Theme.spacing.xs)

                    Text(timeText)
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: Theme.spacing.xs) {
                    Text(lastMsgText)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    Spacer(minLength: Theme.spacing.xs)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.spacing.lg)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { previewWidth = $0 }
        .contentShape(.rect)
        .background {
            NavigationLink(value: Route.chat(id: chat.id)) {
                EmptyView()
            }
            .opacity(0)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
            } label: {
                Label("Pin", systemImage: "pin.fill")
            }

            Button {
            } label: {
                Label("Mute", systemImage: "bell.slash.fill")
            }

            Divider()

            Button(role: .destructive) {
            } label: {
                Label("Delete chat", systemImage: "trash.fill")
            }
        } preview: {
            ChatPreviewView(chat: chat, store: bloomManager.makeMessagesStore(chatID: chat.id), width: previewWidth)
        }
        .tint(.primary)
    }
}
