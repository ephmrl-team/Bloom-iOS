//
//  BloomAPI.swift
//  Bloom
//

import Foundation

/// Everything `BloomManager` needs from a backend. Payloads are raw JSON so the
/// real (`BloomKit`) and mock implementations stay interchangeable.
@MainActor
protocol BloomAPI: AnyObject {
    var onChatsUpdate: (@MainActor (Data) -> Void)? { get set }
    var onUserUpdate: (@MainActor (User) -> Void)? { get set }

    func initialize() throws
    func restoreSession() throws -> Data?
    func register() async throws -> (recoveryPhrase: String?, userJSON: Data)
    func login(recoveryKey: String) async throws -> Data
    func savedRecoveryKey() -> String?
    func clearCredentials()

    func startSync()
    func stopSync()
    func startUserUpdates()
    func stopUserUpdates()
}
