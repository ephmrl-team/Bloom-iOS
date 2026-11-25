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
        static let mnemonic = """
        witch collapse practice feed shame open despair creek road again ice least
        """

        static let me = makeUser(
            id: "user_me",
            username: "mira",
            displayName: "Mira Volkova",
            avatarUrl: "https://i.pravatar.cc/512?img=33"
        )

        static let people = [
            makeUser(
                id: "user_1",
                username: "nina",
                displayName: "Nina Petrova",
                avatarUrl: "https://i.pravatar.cc/512?img=47"
            ),
            makeUser(
                id: "user_2",
                username: "oleg",
                displayName: "Oleg",
                avatarUrl: "https://i.pravatar.cc/512?img=53"
            ),
            makeUser(id: "user_3", username: "group", displayName: "Design team 🎨"),
            makeUser(
                id: "user_4",
                username: "long_name",
                displayName: "Alexandra Konstantinopolskaya",
                avatarUrl: "https://i.pravatar.cc/512?img=44"
            ),
            makeUser(
                id: "user_5",
                username: "sam",
                displayName: "Sam",
                avatarUrl: "https://i.pravatar.cc/512?img=60"
            ),
        ]

        static func encodedChats() throws -> Data {
            let chats: [MockChat]
            switch MockScenario.current {
            case .empty:
                chats = []
            case .normal, .error:
                chats = (0 ..< people.count).map { makeChat(index: $0) }
            case .large:
                chats = (0 ..< 40).map { makeChat(index: $0) }
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

            return (0 ..< count).map { index in
                let date = now.addingTimeInterval(-TimeInterval(count - index) * 60)
                let isMine = index.isMultiple(of: 3)
                return DecryptedMessageWithReply(
                    id: chatID * 1000 + index + 1,
                    content: isMine
                        ? "Reply #\(index + 1)"
                        : "Message #\(index + 1) from \(recipient.displayName ?? recipient.username)",
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

        private static func makeUser(
            id: String,
            username: String,
            displayName: String,
            avatarUrl: String? = nil
        ) -> User {
            User(
                id: id,
                username: username,
                displayName: displayName,
                description: nil,
                avatarUrl: avatarUrl,
                mlKemPublicKey: "7b1f4c9a2e8d6305f1a7c4b9e2d58a0c6f3b7d1e4a9c2f8b5d0e7a3c6b9f2d4e",
                ecdhPublicKey: "d4f8a2c6e0b3d7f1a5c9e2b6d0f4a8c1e5b9d3f7a0c4e8b2d6f1a5c9e3b7d0f4",
                edPublicKey: "1a5e9d3c7b2f6a0e4d8c1b5f9a3e7d2c6b0f4a8e1d5c9b3f7a2e6d0c4b8f1a5e",
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
