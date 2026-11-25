//
//  EmojiFingerprint.swift
//  Bloom
//

import CryptoKit
import Foundation

/// A short emoji fingerprint of the public keys, so two devices can compare them by eye.
enum EmojiFingerprint {
    static let length = 5

    private static let palette = [
        "🌊", "🍒", "🥑", "📷", "🧬", "🌙", "🔥", "🌈",
        "🍀", "🐙", "🍉", "🎲", "🦋", "🌵", "🍋", "🐳",
        "🎈", "🍄", "🪐", "🐝", "🌻", "🍇", "🦊", "🎧",
        "🪁", "🧊", "🍑", "🐬", "🎯", "🦉", "🍩", "🪴",
    ]

    static func emojis(for keys: [String]) -> [String] {
        let digest = SHA256.hash(data: Data(keys.joined(separator: "|").utf8))
        var indices: [Int] = []
        for byte in digest {
            var index = Int(byte) % palette.count
            while indices.contains(index) {
                index = (index + 1) % palette.count
            }
            indices.append(index)
            if indices.count == length {
                break
            }
        }
        return indices.map { palette[$0] }
    }
}
