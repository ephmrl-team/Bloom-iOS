//
//  Fixtures.swift
//  Bloom
//

import Foundation
@testable import Bloom

/// JSON builders shared by the decoding and store tests.
enum Fixtures {
    static func user(_ id: String = "user_me", name: String = "Me") -> User {
        User(
            id: id,
            username: name.lowercased(),
            displayName: name,
            description: nil,
            mlKemPublicKey: "mlkem",
            ecdhPublicKey: "ecdh",
            edPublicKey: "ed25519",
            date: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    static func userJSON(_ user: User) -> Data {
        try! JSONEncoder.bloomEncoder.encode(user)
    }

    static func message(
        id: Int,
        content: String = "hello",
        authorId: String = "user_me",
        seen: Bool = false
    ) -> DecryptedMessageWithReply {
        DecryptedMessageWithReply(
            id: id,
            content: content,
            authorId: authorId,
            timestamp: 1_700_000_000 + Int64(id),
            seen: seen ? Date(timeIntervalSince1970: 1_700_000_100) : nil,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            replyTo: nil
        )
    }

    static func messagesJSON(_ messages: [DecryptedMessageWithReply]) -> Data {
        try! JSONEncoder.bloomEncoder.encode(messages)
    }

    /// `sendMessage` answers with a single message object, not a list.
    static func messageJSON(_ message: DecryptedMessageWithReply) -> Data {
        try! JSONEncoder.bloomEncoder.encode(message)
    }

    /// Chat JSON in the shape the backend sends: `me` and `recipient` are
    /// base64 encoded user objects.
    static func chatJSON(
        id: Int,
        me: User = Fixtures.user(),
        recipient: User? = Fixtures.user("user_1", name: "Ann"),
        lastMessage: DecryptedMessageWithReply? = nil
    ) -> Data {
        var object: [String: Any] = ["id": id, "type": "direct"]
        object["me"] = userJSON(me).base64EncodedString()
        if let recipient {
            object["recipient"] = userJSON(recipient).base64EncodedString()
        }
        if let lastMessage {
            object["last_message"] = try! JSONSerialization.jsonObject(
                with: JSONEncoder.bloomEncoder.encode(lastMessage)
            )
        }
        return try! JSONSerialization.data(withJSONObject: object)
    }

    static func chatsJSON(_ chats: [Int]) -> Data {
        let objects = chats.map { id in
            try! JSONSerialization.jsonObject(with: chatJSON(id: id)) as! [String: Any]
        }
        return try! JSONSerialization.data(withJSONObject: objects)
    }
}

extension JSONEncoder {
    /// Mirrors the decoder: snake_case keys and ISO 8601 dates.
    static let bloomEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(
                date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
            )
        }
        return encoder
    }()
}
