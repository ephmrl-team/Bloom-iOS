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

    init() {
        precondition(
            AppMode.current.allowsRealAPI,
            "BloomKitAPI must not be created in \(AppMode.current.rawValue) mode"
        )

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let storagePath = paths.first?.path,
              let client = ClientNewClient(
                  "https://api.bloomapp.pw",
                  "wss://api.bloomapp.pw/ws",
                  storagePath,
                  Self.databaseKey()
              )
        else {
            // Expects the startup error screen from PLAN 3.1.
            fatalError("Failed to initialize BloomKit client")
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
            KeychainHelper.shared.save(rawRecoveryKey, service: Self.service, account: Self.recoveryAccount)
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

        KeychainHelper.shared.save(recoveryKey, service: Self.service, account: Self.recoveryAccount)
        return payload
    }

    func savedRecoveryKey() -> String? {
        KeychainHelper.shared.read(service: Self.service, account: Self.recoveryAccount)
    }

    func clearCredentials() {
        client.clearCredentials()
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

    private static func databaseKey() -> Data {
        if let base64String = KeychainHelper.shared.read(service: service, account: databaseKeyAccount),
           let existingKey = Data(base64Encoded: base64String) {
            return existingKey
        }

        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let newKey = Data(bytes)
        KeychainHelper.shared.save(newKey.base64EncodedString(), service: service, account: databaseKeyAccount)
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
