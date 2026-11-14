//
//  MessagesStore.swift
//  Bloom
//

import Foundation
import Observation
import OSLog
import DequeModule

struct MessageItem: Identifiable, Hashable, Sendable {
    let id: Int
    let content: String
    let date: String
    let me: Bool
}

@Observable
@MainActor
final class MessagesStore {
    private(set) var data: Deque<MessageItem> = []
    private(set) var isLoading = false
    private(set) var loadFailed = false
    var lastSeenId: Int = 0

    private let chatID: Int
    private let backend: (any BloomAPI)?
    private let currentUserID: String

    init(chatID: Int, backend: any BloomAPI, currentUserID: String) {
        self.chatID = chatID
        self.backend = backend
        self.currentUserID = currentUserID
    }

    /// Empty store for previews.
    init() {
        chatID = 0
        backend = nil
        currentUserID = ""
    }

    func load() async {
        guard let backend else { return }

        isLoading = true
        loadFailed = false
        defer { isLoading = false }

        do {
            let payload = try await backend.messages(chatID: chatID)
            let messages = try JSONDecoder.bloomDecoder.decode([DecryptedMessageWithReply].self, from: payload)
            data = Deque(
                messages
                    .sorted { $0.id < $1.id }
                    .map { MessageItem($0, currentUserID: currentUserID) }
            )
        } catch {
            loadFailed = true
            Logger.bloom.error("messages load failed: \(error, privacy: .public)")
        }
    }

    func send(_ text: String) {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, let backend else { return }

        let pendingID = (data.map(\.id).min() ?? 0) - 1
        data.append(MessageItem(id: pendingID, content: body, date: Self.formatted(.now), me: true))

        Task {
            do {
                let payload = try await backend.sendMessage(chatID: chatID, content: body)
                let message = try JSONDecoder.bloomDecoder.decode(DecryptedMessageWithReply.self, from: payload)
                let item = MessageItem(message, currentUserID: currentUserID)

                if let index = data.firstIndex(where: { $0.id == pendingID }) {
                    data[index] = item
                }
                if message.seen != nil {
                    lastSeenId = item.id
                }
            } catch {
                data.removeAll { $0.id == pendingID }
                Logger.bloom.error("message send failed: \(error, privacy: .public)")
            }
        }
    }

    fileprivate static func formatted(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
}

private extension MessageItem {
    init(_ message: DecryptedMessageWithReply, currentUserID: String) {
        let date = message.timestamp > 0
            ? Date(timeIntervalSince1970: TimeInterval(message.timestamp))
            : message.createdAt

        self.init(
            id: message.id,
            content: message.content,
            date: MessagesStore.formatted(date),
            me: message.authorId == currentUserID
        )
    }
}
