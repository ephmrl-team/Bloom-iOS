//
//  MockData.swift
//  Bloom
//

#if DEBUG
import Foundation

enum MockScenario: String {
    case normal
    case empty
    case error
    case large

    static let current: MockScenario = {
        guard let raw = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("-MockScenario=") })?
            .split(separator: "=", maxSplits: 1)
            .last
        else {
            return .normal
        }
        return MockScenario(rawValue: String(raw)) ?? .normal
    }()
}

enum MockData {
    static let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

    static let me = makeUser(id: "user_me", username: "you", displayName: "You")

    static let people = [
        makeUser(id: "user_1", username: "nina", displayName: "Nina Petrova"),
        makeUser(id: "user_2", username: "oleg", displayName: "Oleg"),
        makeUser(id: "user_3", username: "group", displayName: "Design team 🎨"),
        makeUser(id: "user_4", username: "long_name", displayName: "Alexandra Konstantinopolskaya"),
        makeUser(id: "user_5", username: "sam", displayName: "Sam")
    ]

    static func encodedChats() throws -> Data {
        let chats: [MockChat]
        switch MockScenario.current {
        case .empty:
            chats = []
        case .normal, .error:
            chats = (0..<people.count).map { makeChat(index: $0) }
        case .large:
            chats = (0..<40).map { makeChat(index: $0) }
        }
        let data = try encoder().encode(chats)
        assert(
            (try? JSONDecoder.bloomDecoder.decode([ChatResponse].self, from: data))?.count == chats.count,
            "Mock chat payload no longer matches the ChatResponse contract"
        )
        return data
    }
    static func encoded(_ user: User) throws -> Data {
        try encoder().encode(user)
    }

    static func encoded(_ users: [User]) throws -> Data {
        try encoder().encode(users)
    }

    static func encoded(_ chat: MockChat) throws -> Data {
        try encoder().encode(chat)
    }

    static func chat(with user: User) -> MockChat {
        MockChat(
            id: 1000 + (people.firstIndex { $0.id == user.id } ?? 0),
            title: nil,
            type: "direct",
            me: me,
            recipient: user,
            lastMessage: nil
        )
    }

    static func encoded(_ messages: [DecryptedMessageWithReply]) throws -> Data {
        try encoder().encode(messages)
    }

    static func encoded(_ message: DecryptedMessageWithReply) throws -> Data {
        try encoder().encode(message)
    }

    static func messages(forChatID chatID: Int) -> [DecryptedMessageWithReply] {
        guard MockScenario.current != .empty else { return [] }

        let recipient = people[max(chatID - 1, 0) % people.count]
        let count = 40
        let now = Date()

        return (0..<count).map { index in
            let date = now.addingTimeInterval(-TimeInterval(count - index) * 60)
            let isMine = index.isMultiple(of: 3)
            return DecryptedMessageWithReply(
                id: chatID * 1000 + index + 1,
                content: isMine ? "Reply #\(index + 1)" : "Message #\(index + 1) from \(recipient.displayName ?? recipient.username)",
                authorId: isMine ? me.id : recipient.id,
                timestamp: Int64(date.timeIntervalSince1970),
                seen: isMine ? date : nil,
                createdAt: date,
                replyTo: nil
            )
        }
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeUser(id: String, username: String, displayName: String) -> User {
        User(
            id: id,
            username: username,
            displayName: displayName,
            description: nil,
            mlKemPublicKey: "",
            ecdhPublicKey: "",
            edPublicKey: "",
            date: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private static func makeChat(index: Int) -> MockChat {
        let recipient = people[index % people.count]
        let date = Date().addingTimeInterval(-TimeInterval(index + 1) * 60)
        let lastMessage = DecryptedMessageWithReply(
            id: index + 1,
            content: "Mock message #\(index + 1)",
            authorId: recipient.id,
            timestamp: Int64(date.timeIntervalSince1970),
            seen: nil,
            createdAt: date,
            replyTo: nil
        )
        return MockChat(
            id: index + 1,
            title: nil,
            type: "direct",
            me: me,
            recipient: recipient,
            lastMessage: lastMessage
        )
    }
}

/// Mirrors the JSON shape `BloomKit` sends for a chat: `me`/`recipient` are
/// base64-encoded `User` payloads, not nested objects.
struct MockChat: Encodable {
    let id: Int
    let title: String?
    let type: String
    let me: User
    let recipient: User
    let lastMessage: DecryptedMessageWithReply?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
        case me
        case recipient
        case lastMessage
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(MockData.encoded(me), forKey: .me)
        try container.encode(MockData.encoded(recipient), forKey: .recipient)
        try container.encodeIfPresent(lastMessage, forKey: .lastMessage)
    }
}
#endif
