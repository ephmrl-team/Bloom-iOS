//
//  BloomManagerModels.swift
//  Bloom
//

import Foundation

private extension Date.ISO8601FormatStyle {
    nonisolated static let withFractionalSeconds = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    nonisolated static let withoutFractionalSeconds = Date.ISO8601FormatStyle()
}

public extension JSONDecoder {
    /// Configured once and only read afterwards, so a single instance can serve every decode.
    static let bloomDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = (try? Date.ISO8601FormatStyle.withFractionalSeconds.parse(dateString))
                ?? (try? Date.ISO8601FormatStyle.withoutFractionalSeconds.parse(dateString))
            {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }

        return decoder
    }()
}

public struct User: Codable {
    public let id: String
    public let username: String
    public let displayName: String?
    public let description: String?
    public let mlKemPublicKey: String
    public let ecdhPublicKey: String
    public let edPublicKey: String
    public let date: Date
}

public struct DecryptedMessage: Codable, Identifiable {
    public let id: Int
    public let content: String
    public let authorId: String
    public let timestamp: Int64
    public let seen: Date?
    public let createdAt: Date
}

public struct DecryptedMessageWithReply: Codable, Identifiable {
    public let id: Int
    public let content: String
    public let authorId: String
    public let timestamp: Int64
    public let seen: Date?
    public let createdAt: Date
    public let replyTo: DecryptedMessage?
}

public struct ChatResponse: Codable {
    public let id: Int
    public let members: [User]?
    public let title: String?
    public let type: String
    private let meData: Data?
    private let recipientData: Data?
    public let lastMessage: DecryptedMessageWithReply?

    enum CodingKeys: String, CodingKey {
        case id
        case members
        case title
        case type
        case meData = "me"
        case recipientData = "recipient"
        case lastMessage
    }

    public var me: User? {
        meData.flatMap { try? JSONDecoder.bloomDecoder.decode(User.self, from: $0) }
    }

    public var recipient: User? {
        recipientData.flatMap { try? JSONDecoder.bloomDecoder.decode(User.self, from: $0) }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        members = try container.decodeIfPresent([User].self, forKey: .members)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        type = try container.decode(String.self, forKey: .type)
        meData = try container.decodeIfPresent(Data.self, forKey: .meData)
        recipientData = try container.decodeIfPresent(Data.self, forKey: .recipientData)
        lastMessage = try container.decodeIfPresent(
            DecryptedMessageWithReply.self,
            forKey: .lastMessage
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(members, forKey: .members)
        try container.encode(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(meData, forKey: .meData)
        try container.encode(recipientData, forKey: .recipientData)
        try container.encode(lastMessage, forKey: .lastMessage)
    }
}
