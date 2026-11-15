//
//  DecodingTests.swift
//  Bloom
//

import Foundation
import Testing
@testable import Bloom

@Suite("Backend payload decoding")
struct DecodingTests {
    private let decoder = JSONDecoder.bloomDecoder

    @Test("Decodes snake_case keys")
    func decodesSnakeCase() throws {
        let json = """
        {
          "id": "user_1",
          "username": "ann",
          "display_name": "Ann Lee",
          "description": null,
          "ml_kem_public_key": "mlkem",
          "ecdh_public_key": "ecdh",
          "ed_public_key": "ed",
          "date": "2023-11-14T22:13:20Z"
        }
        """
        let user = try decoder.decode(User.self, from: Data(json.utf8))

        #expect(user.id == "user_1")
        #expect(user.displayName == "Ann Lee")
        #expect(user.description == nil)
    }

    @Test("Accepts ISO 8601 dates with and without fractional seconds")
    func decodesBothDateFormats() throws {
        for raw in ["2023-11-14T22:13:20Z", "2023-11-14T22:13:20.250Z"] {
            let json = "\"\(raw)\""
            let date = try decoder.decode(Date.self, from: Data(json.utf8))
            #expect(date.timeIntervalSince1970 >= 1_700_000_000)
        }
    }

    @Test("Rejects an unknown date format")
    func rejectsBadDate() {
        let json = "\"14.11.2023 22:13\""
        #expect(throws: DecodingError.self) {
            try decoder.decode(Date.self, from: Data(json.utf8))
        }
    }

    @Test("Rejects a user without required keys")
    func rejectsMissingFields() {
        let json = """
        { "id": "user_1", "username": "ann" }
        """
        #expect(throws: DecodingError.self) {
            try decoder.decode(User.self, from: Data(json.utf8))
        }
    }

    @Test("Rejects wrongly typed fields instead of coercing them")
    func rejectsWrongTypes() {
        let json = """
        {
          "id": 1,
          "username": "ann",
          "display_name": null,
          "description": null,
          "ml_kem_public_key": "mlkem",
          "ecdh_public_key": "ecdh",
          "ed_public_key": "ed",
          "date": "2023-11-14T22:13:20Z"
        }
        """
        #expect(throws: DecodingError.self) {
            try decoder.decode(User.self, from: Data(json.utf8))
        }
    }

    @Test("Decodes the chat message list")
    func decodesMessages() throws {
        let data = Fixtures.messagesJSON([
            Fixtures.message(id: 2, content: "second", authorId: "user_1"),
            Fixtures.message(id: 1, content: "first")
        ])
        let messages = try decoder.decode([DecryptedMessageWithReply].self, from: data)

        #expect(messages.map(\.id) == [2, 1])
        #expect(messages[0].content == "second")
        #expect(messages[0].seen == nil)
    }

    @Test("Decodes base64 me and recipient into users")
    func decodesChatParticipants() throws {
        let chat = try decoder.decode(ChatResponse.self, from: Fixtures.chatJSON(id: 3))

        #expect(chat.id == 3)
        #expect(chat.me?.id == "user_me")
        #expect(chat.recipient?.username == "ann")
    }

    @Test("Rejects a chat with a participant payload that is not base64")
    func rejectsBrokenParticipants() {
        let json = """
        { "id": 3, "type": "direct", "me": "not base64 x", "recipient": null }
        """
        #expect(throws: DecodingError.self) {
            try decoder.decode(ChatResponse.self, from: Data(json.utf8))
        }
    }

    @Test("Rejects a chat without an id")
    func rejectsChatWithoutID() {
        let json = """
        { "type": "direct" }
        """
        #expect(throws: DecodingError.self) {
            try decoder.decode(ChatResponse.self, from: Data(json.utf8))
        }
    }

    @Test("Truncated payloads fail instead of crashing")
    func rejectsTruncatedPayload() {
        let data = Data(#"{"id": 1, "type": "di"#.utf8)
        #expect(throws: DecodingError.self) {
            try decoder.decode(ChatResponse.self, from: data)
        }
    }

    @Test("An oversized message body is decoded as data, not executed")
    func decodesLargePayload() throws {
        let content = String(repeating: "a", count: 200_000)
        let data = Fixtures.messagesJSON([Fixtures.message(id: 1, content: content)])
        let messages = try decoder.decode([DecryptedMessageWithReply].self, from: data)

        #expect(messages.first?.content.count == 200_000)
    }
}
