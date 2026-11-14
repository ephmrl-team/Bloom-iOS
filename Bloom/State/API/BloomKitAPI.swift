//
//  BloomKitAPI.swift
//  Bloom
//

import Foundation
import BloomKit
import Bip39

/// The only place in the app that talks to `BloomKit`.
@MainActor
final class BloomKitAPI: BloomAPI {
    var onChatsUpdate: (@MainActor (Data) -> Void)?
    var onUserUpdate: (@MainActor (User) -> Void)?

    private let client: ClientBloomClient
    private let chatsObserver = ChatsObserver()
    private let userObserver = UserObserver()
    private var isObservingChats = false
    private var isObservingUser = false

    private static let service = "pw.bloomapp.auth"
    private static let recoveryAccount = "recoveryKey"
    private static let databaseKeyAccount = "db_encryption_key"

    init() throws {
        precondition(
            AppMode.current.allowsRealAPI,
            "BloomKitAPI must not be created in \(AppMode.current.rawValue) mode"
        )

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let storagePath = paths.first?.path else {
            throw BloomAPIError.missingStorage
        }

        guard let client = ClientNewClient(
            "https://api.bloomapp.pw",
            "wss://api.bloomapp.pw/ws",
            storagePath,
            try Self.databaseKey()
        ) else {
            throw BloomAPIError.clientUnavailable
        }

        self.client = client
    }

    func initialize() throws {
        try client.initialize()
    }

    func restoreSession() throws -> Data? {
        try client.restoreSession().userJSON
    }

    func register() async throws -> (recoveryPhrase: String?, userJSON: Data) {
        let client = self.client
        let result = try await Task.detached(priority: .userInitiated) {
            let result = try client.register()
            return RegisterBackgroundResult(
                rawRecoveryKey: result.rawRecoveryKey,
                userJSON: result.userJSON
            )
        }.value

        guard let userJSON = result.userJSON else {
            throw BloomAPIError.missingPayload
        }

        var recoveryPhrase: String?
        if let rawRecoveryKey = result.rawRecoveryKey {
            let mnemonic = try Mnemonic(entropy: rawRecoveryKey.hexToBytes())
            recoveryPhrase = mnemonic.mnemonic().joined(separator: " ")
            try KeychainHelper.shared.save(rawRecoveryKey, service: Self.service, account: Self.recoveryAccount)
        }

        return (recoveryPhrase, userJSON)
    }

    func login(recoveryKey: String) async throws -> Data {
        let client = self.client
        let payload = try await Task.detached(priority: .userInitiated) { () -> Data? in
            if let restored = try? client.restoreSession(), let userJSON = restored.userJSON {
                return userJSON
            }
            return try client.login(Self.hexKey(from: recoveryKey)).userJSON
        }.value

        guard let payload else {
            throw BloomAPIError.missingPayload
        }

        try KeychainHelper.shared.save(recoveryKey, service: Self.service, account: Self.recoveryAccount)
        return payload
    }

    func messages(chatID: Int) async throws -> Data {
        let client = self.client
        return try await Task.detached(priority: .userInitiated) {
            try client.loadMessages(chatID, beforeID: 0)
        }.value
    }

    func sendMessage(chatID: Int, content: String) async throws -> Data {
        let client = self.client
        return try await Task.detached(priority: .userInitiated) {
            try client.sendMessage(chatID, replyToID: 0, content: content)
        }.value
    }

    func searchUsers(query: String) async throws -> Data {
        let client = self.client
        return try await Task.detached(priority: .userInitiated) {
            try client.searchUsers(query)
        }.value
    }

    func user(id: String) async throws -> Data {
        let client = self.client
        return try await Task.detached(priority: .userInitiated) {
            try client.getUser(id)
        }.value
    }

    func createChat(with user: User) async throws -> Data {
        let client = self.client
        return try await Task.detached(priority: .userInitiated) {
            let request = ClientCreateChatRequest()
            request.userID = user.id
            request.mlKem768PublicKey = user.mlKemPublicKey
            request.x448PublicKey = user.ecdhPublicKey
            request.ed448PublicKey = user.edPublicKey
            return try client.createChat(request)
        }.value
    }

    func savedRecoveryKey() -> String? {
        KeychainHelper.shared.read(service: Self.service, account: Self.recoveryAccount)
    }

    func clearCredentials() {
        client.clearCredentials()
        KeychainHelper.shared.delete(service: Self.service, account: Self.recoveryAccount)
        KeychainHelper.shared.delete(service: Self.service, account: Self.databaseKeyAccount)
    }

    func startSync() {
        guard !isObservingChats else { return }
        chatsObserver.onUpdate = { [weak self] data in
            self?.onChatsUpdate?(data)
        }
        client.register(chatsObserver)
        client.startChatsSync()
        isObservingChats = true
    }

    func stopSync() {
        guard isObservingChats else { return }
        client.stopChatsSync()
        client.unregisterChatsListener()
        isObservingChats = false
    }

    func startUserUpdates() {
        guard !isObservingUser else { return }
        userObserver.onUpdate = { [weak self] user in
            self?.onUserUpdate?(user)
        }
        client.register(userObserver)
        isObservingUser = true
    }

    func stopUserUpdates() {
        guard isObservingUser else { return }
        client.unregisterUserListener()
        isObservingUser = false
    }

    private static func databaseKey() throws -> Data {
        if let base64String = KeychainHelper.shared.read(service: service, account: databaseKeyAccount),
           let existingKey = Data(base64Encoded: base64String) {
            return existingKey
        }

        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }

        let newKey = Data(bytes)
        try KeychainHelper.shared.save(
            newKey.base64EncodedString(),
            service: service,
            account: databaseKeyAccount
        )
        return newKey
    }

    private nonisolated static func hexKey(from recoveryKey: String) throws -> String {
        guard recoveryKey.contains(" ") else {
            return recoveryKey
        }
        let mnemonic = try Mnemonic(mnemonic: recoveryKey.components(separatedBy: " "))
        return mnemonic.entropy.map { String(format: "%02x", $0) }.joined()
    }
}

/// Carries the client's result across the background task boundary.
private struct RegisterBackgroundResult: Sendable {
    let rawRecoveryKey: String?
    let userJSON: Data?
}
