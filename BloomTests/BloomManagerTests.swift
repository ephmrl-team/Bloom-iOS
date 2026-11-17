//
//  BloomManagerTests.swift
//  Bloom
//

@testable import Bloom
import Foundation
import Testing

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
    func restoresSession() async throws {
        let api = FakeAPI()
        api.restoreData = try Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)

        #expect(await eventually { manager.hasRestoredSession })
        #expect(manager.currentUser?.id == "user_me")
        #expect(api.syncStartCount == 1)
        #expect(api.userUpdateStartCount == 1)
    }

    @Test("Starts without a saved session")
    func startsWithoutSession() async {
        let api = FakeAPI()
        api.restoreError = StubError()
        let manager = BloomManager(backend: api)

        #expect(await eventually { manager.startup == .ready })
        #expect(manager.hasRestoredSession == false)
        #expect(manager.currentUser == nil)
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
    func logsInWithKey() async throws {
        let api = FakeAPI()
        api.loginData = try Fixtures.userJSON(Fixtures.user("user_1", name: "Ann"))
        let manager = BloomManager(backend: api)

        let user = await manager.loginUser(recoveryKey: "a b c")

        #expect(user?.id == "user_1")
        #expect(api.loginKeys == ["a b c"])
        #expect(manager.currentUser?.id == "user_1")
        #expect(api.syncStartCount == 1)
    }

    @Test("Falls back to the saved recovery key")
    func logsInWithSavedKey() async throws {
        let api = FakeAPI()
        api.savedKey = "saved"
        api.loginData = try Fixtures.userJSON(Fixtures.user())
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
    func registersUser() async throws {
        let api = FakeAPI()
        api.registerResult = (recoveryPhrase: "a b c", userJSON: try Fixtures.userJSON(Fixtures.user()))
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

    @Test("Logs out and clears every trace of the session")
    func logoutClearsSession() async throws {
        let api = FakeAPI()
        api.loginData = try Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)
        _ = await manager.loginUser(recoveryKey: "key")
        api.onChatsUpdate?(try Fixtures.chatsJSON([1]))

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
}
