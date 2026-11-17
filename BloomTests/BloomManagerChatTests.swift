//
//  BloomManagerChatTests.swift
//  Bloom
//

@testable import Bloom
import Foundation
import Testing

@Suite("Bloom manager chats")
struct BloomManagerChatTests {
    @Test("Replaces the chat list from a backend update")
    func appliesChatUpdates() async throws {
        let api = FakeAPI()
        api.loginData = try Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)
        _ = await manager.loginUser(recoveryKey: "key")

        api.onChatsUpdate?(try Fixtures.chatsJSON([7, 8]))

        #expect(manager.conversations.map(\.id) == [7, 8])
        #expect(manager.hasLoadedChats)
    }

    @Test("Keeps the previous chat list when an update is malformed")
    func keepsChatsOnBrokenUpdate() async throws {
        let api = FakeAPI()
        api.loginData = try Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)
        _ = await manager.loginUser(recoveryKey: "key")
        api.onChatsUpdate?(try Fixtures.chatsJSON([7]))

        api.onChatsUpdate?(Data("{\"id\":".utf8))

        #expect(manager.conversations.map(\.id) == [7])
        #expect(manager.hasChatListError)
    }

    @Test("Clears the chat list error once a readable payload arrives")
    func clearsChatListError() async throws {
        let api = FakeAPI()
        api.loginData = try Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)
        _ = await manager.loginUser(recoveryKey: "key")
        api.onChatsUpdate?(Data("{\"id\":".utf8))

        api.onChatsUpdate?(try Fixtures.chatsJSON([7]))

        #expect(manager.hasChatListError == false)
    }

    @Test("Opens a chat once and keeps it at the top")
    func openChatInsertsOnce() async throws {
        let api = FakeAPI()
        api.createChatData = try Fixtures.chatJSON(id: 42)
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
        api.searchResult = .success(try JSONEncoder.bloomEncoder.encode([Fixtures.user("user_1")]))
        let manager = BloomManager(backend: api)

        let found = try await manager.searchUsers("ann")
        #expect(found.map(\.id) == ["user_1"])
        #expect(api.searchQueries == ["ann"])

        api.searchResult = .failure(StubError())
        await #expect(throws: StubError.self) {
            try await manager.searchUsers("ann")
        }
    }

    @Test("Builds a message store bound to the current user")
    func makesMessagesStore() async throws {
        let api = FakeAPI()
        api.loginData = try Fixtures.userJSON(Fixtures.user())
        let manager = BloomManager(backend: api)
        _ = await manager.loginUser(recoveryKey: "key")
        api.messagesData = try Fixtures.messagesJSON([
            Fixtures.message(id: 1, authorId: "user_me"),
            Fixtures.message(id: 2, authorId: "user_1")
        ])

        let store = manager.makeMessagesStore(chatID: 5)
        await store.load()

        #expect(store.data.map(\.me) == [true, false])
    }
}
