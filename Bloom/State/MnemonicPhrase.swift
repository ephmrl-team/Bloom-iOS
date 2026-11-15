//
//  MnemonicPhrase.swift
//  Bloom
//

import Foundation
import Bip39

/// Validation for the 12-word login phrase.
enum MnemonicPhrase {
    static let wordCount = 12

    /// Trims and lowercases every word. The Bip39 word list compares exact
    /// strings, so the normalisation has to happen before validation.
    static func normalize(_ words: [String]) -> [String] {
        words.map {
            $0.precomposedStringWithCompatibilityMapping
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        }
    }

    /// Splits pasted text on any whitespace run.
    static func words(from text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    static func isValid(_ words: [String]) -> Bool {
        let normalized = normalize(words)
        guard normalized.count == wordCount, !normalized.contains(where: \.isEmpty) else {
            return false
        }
        return Mnemonic.isValid(phrase: normalized)
    }

    static func phrase(from words: [String]) -> String {
        normalize(words).joined(separator: " ")
    }
}
