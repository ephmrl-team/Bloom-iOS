//
//  BloomManager.swift
//  Bloom
//

import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class BloomManager {
    var currentUser: User?
    var conversations: [ChatResponse] = []

    @ObservationIgnored private let backend: any BloomAPI

    init(backend: any BloomAPI) {
        self.backend = backend

        backend.onUserUpdate = { [weak self] user in
            self?.currentUser = user
        }

        do {
            try backend.initialize()
            if let data = try backend.restoreSession(),
               let user = try? JSONDecoder.bloomDecoder.decode(User.self, from: data) {
                setupSession(user: user)
            }
        } catch {
            Logger.bloom.error("backend failed to start: \(error, privacy: .public)")
        }
    }

    func registerUser() async -> (user: User?, mnemonic: String?) {
        do {
            let result = try await backend.register()
            let user = try JSONDecoder.bloomDecoder.decode(User.self, from: result.userJSON)
            setupSession(user: user)
            return (user, result.recoveryPhrase)
        } catch {
            Logger.bloom.error("register failed: \(error, privacy: .public)")
            return (nil, nil)
        }
    }

    func loginUser(recoveryKey: String? = nil) async -> User? {
        guard let key = recoveryKey ?? backend.savedRecoveryKey() else { return nil }

        do {
            let data = try await backend.login(recoveryKey: key)
            let user = try JSONDecoder.bloomDecoder.decode(User.self, from: data)
            setupSession(user: user)
            return user
        } catch {
            Logger.bloom.error("login failed: \(error, privacy: .public)")
            return nil
        }
    }

    func checkSession() -> Bool {
        backend.savedRecoveryKey() != nil
    }

    func logout() {
        stopSyncingChats()
        backend.stopUserUpdates()
        backend.clearCredentials()
        currentUser = nil
    }

    private func setupSession(user: User) {
        currentUser = user
        backend.startUserUpdates()
        startSyncingChats()
    }

    private func startSyncingChats() {
        backend.onChatsUpdate = { [weak self] data in
            self?.parseAndSetChats(data)
        }
        backend.startSync()
    }

    private func stopSyncingChats() {
        backend.stopSync()
        backend.onChatsUpdate = nil
    }

    private func parseAndSetChats(_ data: Data) {
        do {
            conversations = try JSONDecoder.bloomDecoder.decode([ChatResponse].self, from: data)
        } catch {
            Logger.bloom.error("chat list decode failed: \(error, privacy: .public)")
        }
    }
}
