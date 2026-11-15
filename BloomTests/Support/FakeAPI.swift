//
//  FakeAPI.swift
//  Bloom
//

import Foundation
@testable import Bloom

struct StubError: Error {}

@MainActor
final class FakeAPI: BloomAPI {
    var onChatsUpdate: (@MainActor (Data) -> Void)?
    var onUserUpdate: (@MainActor (User) -> Void)?

    var initializeError: Error?
    var restoreData: Data?
    var registerResult: (recoveryPhrase: String?, userJSON: Data)?
    var loginData: Data?
    var messagesData: Data?
    var sendResult: Result<Data, Error>?
    var searchResult: Result<Data, Error>?
    var userData: Data?
    var createChatData: Data?
    var savedKey: String?

    private(set) var initializeCount = 0
    private(set) var syncStartCount = 0
    private(set) var syncStopCount = 0
    private(set) var userUpdateStartCount = 0
    private(set) var userUpdateStopCount = 0
    private(set) var clearedCredentials = false
    private(set) var sentMessages: [(chatID: Int, content: String)] = []
    private(set) var loginKeys: [String] = []
    private(set) var searchQueries: [String] = []

    func initialize() throws {
        initializeCount += 1
        if let initializeError { throw initializeError }
    }

    func restoreSession() throws -> Data? { restoreData }

    func register() async throws -> (recoveryPhrase: String?, userJSON: Data) {
        guard let registerResult else { throw StubError() }
        return registerResult
    }

    func login(recoveryKey: String) async throws -> Data {
        loginKeys.append(recoveryKey)
        guard let loginData else { throw StubError() }
        return loginData
    }

    func messages(chatID: Int) async throws -> Data {
        guard let messagesData else { throw StubError() }
        return messagesData
    }

    func sendMessage(chatID: Int, content: String) async throws -> Data {
        sentMessages.append((chatID, content))
        guard let sendResult else { throw StubError() }
        return try sendResult.get()
    }

    func searchUsers(query: String) async throws -> Data {
        searchQueries.append(query)
        guard let searchResult else { throw StubError() }
        return try searchResult.get()
    }

    func user(id: String) async throws -> Data {
        guard let userData else { throw StubError() }
        return userData
    }

    func createChat(with user: User) async throws -> Data {
        guard let createChatData else { throw StubError() }
        return createChatData
    }

    func savedRecoveryKey() -> String? { savedKey }

    func clearCredentials() {
        clearedCredentials = true
        savedKey = nil
        restoreData = nil
    }

    func startSync() { syncStartCount += 1 }
    func stopSync() { syncStopCount += 1 }
    func startUserUpdates() { userUpdateStartCount += 1 }
    func stopUserUpdates() { userUpdateStopCount += 1 }
}
