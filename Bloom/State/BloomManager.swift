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
    enum Startup {
        case starting
        case ready
        case failed
    }

    var currentUser: User?
    var conversations: [ChatResponse] = []
    private(set) var startup: Startup = .starting
    private(set) var hasRestoredSession = false

    @ObservationIgnored private let backend: any BloomAPI

    init(backend: any BloomAPI) {
        self.backend = backend

        backend.onUserUpdate = { [weak self] user in
            self?.currentUser = user
        }

        Task { await start() }
    }

    func start() async {
        startup = .starting
        do {
            try backend.initialize()
            if let data = try backend.restoreSession() {
                do {
                    let user = try JSONDecoder.bloomDecoder.decode(User.self, from: data)
                    hasRestoredSession = true
                    setupSession(user: user)
                } catch {
                    Logger.bloom.error("restored session decode failed: \(error, privacy: .public)")
                }
            }
            startup = .ready
        } catch {
            Logger.bloom.error("backend failed to start: \(error, privacy: .public)")
            startup = .failed
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
        conversations = []
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
