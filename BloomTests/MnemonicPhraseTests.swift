//
//  MnemonicPhraseTests.swift
//  Bloom
//

import Testing
@testable import Bloom

@Suite("Mnemonic phrase")
struct MnemonicPhraseTests {
    /// BIP39 test vector: 128 bits of zero entropy.
    private let valid = [
        "abandon", "abandon", "abandon", "abandon", "abandon", "abandon",
        "abandon", "abandon", "abandon", "abandon", "abandon", "about"
    ]

    @Test("Accepts a valid 12-word phrase")
    func acceptsValidPhrase() {
        #expect(MnemonicPhrase.isValid(valid))
    }

    @Test("Rejects a phrase with a broken checksum")
    func rejectsBrokenChecksum() {
        var words = valid
        words[11] = "abandon"
        #expect(!MnemonicPhrase.isValid(words))
    }

    @Test("Rejects a phrase with the wrong word count")
    func rejectsWrongWordCount() {
        #expect(!MnemonicPhrase.isValid(Array(valid.prefix(11))))
        #expect(!MnemonicPhrase.isValid(valid + ["about"]))
    }

    @Test("Rejects words outside the BIP39 list")
    func rejectsUnknownWord() {
        var words = valid
        words[0] = "bloom"
        #expect(!MnemonicPhrase.isValid(words))
    }

    @Test("Rejects empty input")
    func rejectsEmptyWords() {
        #expect(!MnemonicPhrase.isValid(Array(repeating: "", count: 12)))
    }

    @Test("Normalises case and surrounding whitespace")
    func normalisesInput() {
        let messy = valid.map { "  \($0.uppercased())\n" }
        #expect(MnemonicPhrase.isValid(messy))
    }

    @Test("Joins normalised words into the phrase sent to the backend")
    func joinsPhrase() {
        let phrase = MnemonicPhrase.phrase(from: valid.map { " \($0.uppercased()) " })
        #expect(phrase == valid.joined(separator: " "))
    }

    @Test("Splits pasted text on whitespace")
    func splitsPastedText() {
        #expect(MnemonicPhrase.words(from: " abandon\tabandon \n about ") == ["abandon", "abandon", "about"])
    }
}
