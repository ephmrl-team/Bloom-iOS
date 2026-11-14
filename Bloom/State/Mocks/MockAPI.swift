//
//  MockAPI.swift
//  Bloom
//

#if DEBUG
import Foundation

/// In-memory backend for `AppMode.mock`: no BloomKit client, no network,
/// no Keychain. State lives only for the lifetime of the process.
@MainActor
final class MockAPI: BloomAPI {
    var onChatsUpdate: (@MainActor (Data) -> Void)?
    var onUserUpdate: (@MainActor (User) -> Void)?

    private let scenario = MockScenario.current
    private let latency = Duration.milliseconds(150)
    private var recoveryKey: String?
    private var syncTask: Task<Void, Never>?
    private var messagesByChat: [Int: [DecryptedMessageWithReply]] = [:]

    func initialize() throws {}

    func restoreSession() throws -> Data? {
        nil
    }

    func register() async throws -> (recoveryPhrase: String?, userJSON: Data) {
        try await Task.sleep(for: latency)
        try failIfNeeded()
        recoveryKey = MockData.mnemonic
        return (MockData.mnemonic, try MockData.encoded(MockData.me))
    }

    func login(recoveryKey: String) async throws -> Data {
        try await Task.sleep(for: latency)
        try failIfNeeded()
        self.recoveryKey = recoveryKey
        return try MockData.encoded(MockData.me)
    }

    func messages(chatID: Int) async throws -> Data {
        try await Task.sleep(for: latency)
        try failIfNeeded()
        return try MockData.encoded(messages(for: chatID))
    }

    func sendMessage(chatID: Int, content: String) async throws -> Data {
        try await Task.sleep(for: latency)
        try failIfNeeded()

        var stored = messages(for: chatID)
        let message = DecryptedMessageWithReply(
            id: (stored.last?.id ?? 0) + 1,
            content: content,
            authorId: MockData.me.id,
            timestamp: Int64(Date().timeIntervalSince1970),
            seen: nil,
            createdAt: .now,
            replyTo: nil
        )
        stored.append(message)
        messagesByChat[chatID] = stored
        return try MockData.encoded(message)
    }

    func searchUsers(query: String) async throws -> Data {
        try await Task.sleep(for: latency)
        try failIfNeeded()

        let text = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let people = text.isEmpty ? MockData.people : MockData.people.filter { user in
            user.username.lowercased().contains(text)
                || (user.displayName ?? "").lowercased().contains(text)
        }
        return try MockData.encoded(people)
    }

    func user(id: String) async throws -> Data {
        try await Task.sleep(for: latency)
        try failIfNeeded()

        guard let user = MockData.people.first(where: { $0.id == id }) ?? (id == MockData.me.id ? MockData.me : nil) else {
            throw BloomAPIError.missingPayload
        }
        return try MockData.encoded(user)
    }

    func createChat(with user: User) async throws -> Data {
        try await Task.sleep(for: latency)
        try failIfNeeded()

        let chat = MockData.chat(with: user)
        messagesByChat[chat.id] = MockData.messages(forChatID: chat.id)
        return try MockData.encoded(chat)
    }

    func savedRecoveryKey() -> String? {
        recoveryKey
    }

    func clearCredentials() {
        recoveryKey = nil
    }

    func startSync() {
        syncTask?.cancel()
        syncTask = Task { @MainActor in
            try? await Task.sleep(for: latency)
            guard !Task.isCancelled, let data = try? MockData.encodedChats() else { return }
            onChatsUpdate?(data)
        }
    }

    func stopSync() {
        syncTask?.cancel()
        syncTask = nil
    }

    func startUserUpdates() {}

    func stopUserUpdates() {}

    private func messages(for chatID: Int) -> [DecryptedMessageWithReply] {
        if let stored = messagesByChat[chatID] {
            return stored
        }

        let seeded = MockData.messages(forChatID: chatID)
        messagesByChat[chatID] = seeded
        return seeded
    }

    private func failIfNeeded() throws {
        if scenario == .error {
            throw BloomAPIError.unavailable
        }
    }
}
#endif
