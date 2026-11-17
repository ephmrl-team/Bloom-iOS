//
//  MessagesStoreTests.swift
//  Bloom
//

@testable import Bloom
import Foundation
import Testing

@Suite("Messages store")
struct MessagesStoreTests {
    /// `send` starts an unstructured task, so the assertion waits for its result.
    private static func eventually(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<200 {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }

    @Test("Loads messages sorted by id")
    func loadsMessagesSorted() async throws {
        let api = FakeAPI()
        api.messagesData = try Fixtures.messagesJSON([
            Fixtures.message(id: 3),
            Fixtures.message(id: 1),
            Fixtures.message(id: 2)
        ])
        let store = MessagesStore(chatID: 1, backend: api, currentUserID: "user_me")

        await store.load()

        #expect(store.data.map(\.id) == [1, 2, 3])
        #expect(store.isLoading == false)
        #expect(store.loadFailed == false)
    }

    @Test("Marks own messages")
    func marksOwnMessages() async throws {
        let api = FakeAPI()
        api.messagesData = try Fixtures.messagesJSON([
            Fixtures.message(id: 1, authorId: "user_me"),
            Fixtures.message(id: 2, authorId: "user_1")
        ])
        let store = MessagesStore(chatID: 1, backend: api, currentUserID: "user_me")

        await store.load()

        #expect(store.data.map(\.me) == [true, false])
    }

    @Test("Reports a failed load")
    func reportsFailedLoad() async {
        let api = FakeAPI()
        api.messagesData = Data("{".utf8)
        let store = MessagesStore(chatID: 1, backend: api, currentUserID: "user_me")

        await store.load()

        #expect(store.loadFailed)
        #expect(store.data.isEmpty)
        #expect(store.isLoading == false)
    }

    @Test("Shows the message immediately and replaces it with the server copy")
    func sendsOptimistically() async throws {
        let api = FakeAPI()
        api.sendResult = .success(try Fixtures.messageJSON(Fixtures.message(id: 10, content: "hi")))
        let store = MessagesStore(chatID: 1, backend: api, currentUserID: "user_me")

        store.send("  hi \n")
        #expect(store.data.count == 1)
        #expect(store.data.first?.id == -1)
        let renderID = store.data.first?.renderID

        let replaced = await Self.eventually { store.data.first?.id == 10 }
        #expect(replaced)
        #expect(store.data.first?.renderID == renderID)
        #expect(api.sentMessages.first?.content == "hi")
    }

    @Test("Removes the pending message when sending fails")
    func rollsBackFailedSend() async {
        let api = FakeAPI()
        api.sendResult = .failure(StubError())
        let store = MessagesStore(chatID: 1, backend: api, currentUserID: "user_me")

        store.send("hi")
        #expect(store.data.count == 1)

        let rolledBack = await Self.eventually { store.data.isEmpty }
        #expect(rolledBack)
    }

    @Test("Ignores empty messages")
    func ignoresEmptyMessage() {
        let api = FakeAPI()
        let store = MessagesStore(chatID: 1, backend: api, currentUserID: "user_me")

        store.send("   \n ")

        #expect(store.data.isEmpty)
        #expect(api.sentMessages.isEmpty)
    }

    @Test("Records the seen id when the server confirms it")
    func recordsSeenID() async throws {
        let api = FakeAPI()
        api.sendResult = .success(try Fixtures.messageJSON(Fixtures.message(id: 11, seen: true)))
        let store = MessagesStore(chatID: 1, backend: api, currentUserID: "user_me")

        store.send("hi")

        let seen = await Self.eventually { store.lastSeenId == 11 }
        #expect(seen)
    }

    @Test("A store without a backend stays empty")
    func previewStoreIsInert() async {
        let store = MessagesStore()

        await store.load()
        store.send("hi")

        #expect(store.data.isEmpty)
        #expect(store.isLoading == false)
        #expect(store.loadFailed == false)
    }
}
