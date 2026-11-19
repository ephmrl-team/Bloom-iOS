//
//  MessagesStore.swift
//  Bloom
//

import DequeModule
import Foundation
import Observation
import OSLog

struct MessageItem: Identifiable, Hashable, Sendable {
    let id: Int
    let content: String
    let date: String
    let me: Bool
    let renderID: UUID

    init(id: Int, content: String, date: String, me: Bool, renderID: UUID = UUID()) {
        self.id = id
        self.content = content
        self.date = date
        self.me = me
        self.renderID = renderID
    }
}

@Observable
@MainActor
final class MessagesStore {
    private(set) var data: Deque<MessageItem> = []
    private(set) var appearingMessageIDs: Set<UUID> = []
    private(set) var isLoading = false
    private(set) var loadFailed = false
    var lastSeenId: Int = 0

    private let chatID: Int
    private let backend: (any BloomAPI)?
    private let currentUserID: String
    /// Pending rows count down from -1, so no scan of `data` is needed per send.
    private var nextPendingID = -1

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

        // Demo hold: keeps the skeleton on screen long enough to read.
        try? await Task.sleep(for: .milliseconds(1000))

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

        let pendingID = nextPendingID
        nextPendingID -= 1
        let item = MessageItem(id: pendingID, content: body, date: Self.formatted(.now), me: true)
        appearingMessageIDs.insert(item.renderID)
        data.append(item)

        Task {
            do {
                let payload = try await backend.sendMessage(chatID: chatID, content: body)
                let message = try JSONDecoder.bloomDecoder.decode(DecryptedMessageWithReply.self, from: payload)
                if let index = data.firstIndex(where: { $0.id == pendingID }) {
                    let item = MessageItem(message, currentUserID: currentUserID, renderID: data[index].renderID)
                    data[index] = item
                }
                if message.seen != nil {
                    lastSeenId = message.id
                }
            } catch {
                appearingMessageIDs.remove(item.renderID)
                data.removeAll { $0.id == pendingID }
                Logger.bloom.error("message send failed: \(error, privacy: .public)")
            }
        }
    }

    func didShowMessage(_ id: UUID) {
        appearingMessageIDs.remove(id)
    }

    fileprivate static func formatted(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
}

private extension MessageItem {
    init(_ message: DecryptedMessageWithReply, currentUserID: String, renderID: UUID = UUID()) {
        let date = message.timestamp > 0
            ? Date(timeIntervalSince1970: TimeInterval(message.timestamp))
            : message.createdAt

        self.init(
            id: message.id,
            content: message.content,
            date: MessagesStore.formatted(date),
            me: message.authorId == currentUserID,
            renderID: renderID
        )
    }
}
