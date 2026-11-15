//
//  BloomManagerTests.swift
//  Bloom
//

import Foundation
import Testing
@testable import Bloom

@Suite("Bloom manager")
struct BloomManagerTests {
    @Test("Reports ready after the backend starts")
    func startsReady() async {
        let api = FakeAPI()
        let manager = BloomManager(backend: api)

        #expect(await eventually { manager.startup == .ready })
        #expect(api.initializeCount == 1)
        #expect(manager.hasRestoredSession == false)
    }

    @Test("Surfaces a failed start")
    func reportsFailedStart() async {
        let api = FakeAPI()
        api.initializeError = StubError()
        let manager = BloomManager(backend: api)

        #expect(await eventually { manager.startup == .failed })
        #expect(manager.currentUser == nil)
        #expect(api.syncStartCount == 0)
    }

    @Test("Restores a stored session")
    func restoresSession() async {
        let api = FakeAPI()
        api.restoreData = Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)

        #expect(await eventually { manager.hasRestoredSession })
        #expect(manager.currentUser?.id == "user_me")
        #expect(api.syncStartCount == 1)
        #expect(api.userUpdateStartCount == 1)
    }

    @Test("Ignores a session payload it cannot decode")
    func ignoresBrokenSession() async {
        let api = FakeAPI()
        api.restoreData = Data("{".utf8)
        let manager = BloomManager(backend: api)

        #expect(await eventually { manager.startup == .ready })
        #expect(manager.hasRestoredSession == false)
        #expect(manager.currentUser == nil)
    }

    @Test("Logs in with the supplied recovery key")
    func logsInWithKey() async {
        let api = FakeAPI()
        api.loginData = Fixtures.userJSON(Fixtures.user("user_1", name: "Ann"))
        let manager = BloomManager(backend: api)

        let user = await manager.loginUser(recoveryKey: "a b c")

        #expect(user?.id == "user_1")
        #expect(api.loginKeys == ["a b c"])
        #expect(manager.currentUser?.id == "user_1")
        #expect(api.syncStartCount == 1)
    }

    @Test("Falls back to the saved recovery key")
    func logsInWithSavedKey() async {
        let api = FakeAPI()
        api.savedKey = "saved"
        api.loginData = Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)

        _ = await manager.loginUser()

        #expect(api.loginKeys == ["saved"])
    }

    @Test("Does not log in without any key")
    func refusesLoginWithoutKey() async {
        let api = FakeAPI()
        let manager = BloomManager(backend: api)

        let user = await manager.loginUser()

        #expect(user == nil)
        #expect(api.loginKeys.isEmpty)
        #expect(manager.currentUser == nil)
    }

    @Test("Returns nil when the login fails")
    func reportsFailedLogin() async {
        let api = FakeAPI()
        let manager = BloomManager(backend: api)

        let user = await manager.loginUser(recoveryKey: "key")

        #expect(user == nil)
        #expect(manager.currentUser == nil)
    }

    @Test("Registers and exposes the recovery phrase")
    func registersUser() async {
        let api = FakeAPI()
        api.registerResult = (recoveryPhrase: "a b c", userJSON: Fixtures.userJSON(Fixtures.user()))
        let manager = BloomManager(backend: api)

        let result = await manager.registerUser()

        #expect(result.user?.id == "user_me")
        #expect(result.mnemonic == "a b c")
        #expect(manager.currentUser?.id == "user_me")
    }

    @Test("Returns nothing when registration fails")
    func reportsFailedRegistration() async {
        let api = FakeAPI()
        let manager = BloomManager(backend: api)

        let result = await manager.registerUser()

        #expect(result.user == nil)
        #expect(result.mnemonic == nil)
    }

    @Test("Replaces the chat list from a backend update")
    func appliesChatUpdates() async {
        let api = FakeAPI()
        api.loginData = Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)
        _ = await manager.loginUser(recoveryKey: "key")

        api.onChatsUpdate?(Fixtures.chatsJSON([7, 8]))

        #expect(manager.conversations.map(\.id) == [7, 8])
        #expect(manager.hasLoadedChats)
    }

    @Test("Keeps the previous chat list when an update is malformed")
    func keepsChatsOnBrokenUpdate() async {
        let api = FakeAPI()
        api.loginData = Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)
        _ = await manager.loginUser(recoveryKey: "key")
        api.onChatsUpdate?(Fixtures.chatsJSON([7]))

        api.onChatsUpdate?(Data("{\"id\":".utf8))

        #expect(manager.conversations.map(\.id) == [7])
    }

    @Test("Opens a chat once and keeps it at the top")
    func openChatInsertsOnce() async {
        let api = FakeAPI()
        api.createChatData = Fixtures.chatJSON(id: 42)
        let manager = BloomManager(backend: api)
        let peer = Fixtures.user("user_1", name: "Ann")

        #expect(await manager.openChat(with: peer) == 42)
        #expect(await manager.openChat(with: peer) == 42)
        #expect(manager.conversations.map(\.id) == [42])
    }

    @Test("Returns nil when a chat cannot be created")
    func reportsFailedChatCreation() async {
        let api = FakeAPI()
        let manager = BloomManager(backend: api)

        #expect(await manager.openChat(with: Fixtures.user()) == nil)
        #expect(manager.conversations.isEmpty)
    }

    @Test("Searches users and propagates failures")
    func searchesUsers() async throws {
        let api = FakeAPI()
        api.searchResult = .success(try! JSONEncoder.bloomEncoder.encode([Fixtures.user("user_1")]))
        let manager = BloomManager(backend: api)

        let found = try await manager.searchUsers("ann")
        #expect(found.map(\.id) == ["user_1"])
        #expect(api.searchQueries == ["ann"])

        api.searchResult = .failure(StubError())
        await #expect(throws: StubError.self) {
            try await manager.searchUsers("ann")
        }
    }

    @Test("Logs out and clears every trace of the session")
    func logoutClearsSession() async {
        let api = FakeAPI()
        api.loginData = Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)
        _ = await manager.loginUser(recoveryKey: "key")
        api.onChatsUpdate?(Fixtures.chatsJSON([1]))

        manager.logout()

        #expect(manager.currentUser == nil)
        #expect(manager.conversations.isEmpty)
        #expect(api.clearedCredentials)
        #expect(api.syncStopCount == 1)
        #expect(api.userUpdateStopCount == 1)
        #expect(api.onChatsUpdate == nil)
        #expect(manager.checkSession() == false)
    }

    @Test("Reports a saved session")
    func checkSession() {
        let api = FakeAPI()
        let manager = BloomManager(backend: api)

        #expect(manager.checkSession() == false)

        api.savedKey = "key"

        #expect(manager.checkSession())
    }

    @Test("Builds a message store bound to the current user")
    func makesMessagesStore() async {
        let api = FakeAPI()
        api.loginData = Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)
        _ = await manager.loginUser(recoveryKey: "key")
        api.messagesData = Fixtures.messagesJSON([
            Fixtures.message(id: 1, authorId: "user_me"),
            Fixtures.message(id: 2, authorId: "user_1")
        ])

        let store = manager.makeMessagesStore(chatID: 5)
        await store.load()

        #expect(store.data.map(\.me) == [true, false])
    }
}
