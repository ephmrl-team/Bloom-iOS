//
//  FormattingTests.swift
//  Bloom
//

import UIKit
import Testing
@testable import Bloom

@Suite("Formatting helpers")
struct FormattingTests {
    private func components(_ color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    private func expectColor(_ hex: String, _ expected: (CGFloat, CGFloat, CGFloat, CGFloat)) {
        let actual = components(UIColor(hex: hex))
        #expect(abs(actual.r - expected.0) < 0.01)
        #expect(abs(actual.g - expected.1) < 0.01)
        #expect(abs(actual.b - expected.2) < 0.01)
        #expect(abs(actual.a - expected.3) < 0.01)
    }

    @Test("Parses six digit hex colours")
    func parsesSixDigits() {
        expectColor("#1A8CFF", (26 / 255, 140 / 255, 255 / 255, 1))
        expectColor("000000", (0, 0, 0, 1))
        expectColor("FFFFFF", (1, 1, 1, 1))
    }

    @Test("Parses three digit and eight digit hex colours")
    func parsesShortAndAlphaHex() {
        expectColor("#fff", (1, 1, 1, 1))
        expectColor("#f00", (1, 0, 0, 1))
        expectColor("FF000080", (1, 0, 0, 128 / 255))
    }

    @Test("Falls back to white for an unsupported length")
    func fallsBackToWhite() {
        expectColor("", (1, 1, 1, 1))
        expectColor("#12345", (1, 1, 1, 1))
    }

    @Test("Converts hex strings to bytes")
    func convertsHexToBytes() {
        #expect("48656c6c6f".hexToBytes() == Array("Hello".utf8))
        #expect("48 65 6C 6C 6F".hexToBytes() == Array("Hello".utf8))
        #expect("zz".hexToBytes().isEmpty)
        #expect("4".hexToBytes().isEmpty)
        #expect("4g6".hexToBytes().isEmpty)
    }

    @Test("Builds initials from a name")
    func buildsInitials() {
        #expect(initials(from: "Ann Lee") == "AL")
        #expect(initials(from: "ann") == "A")
        #expect(initials(from: "Ann Marie Lee") == "AM")
        #expect(initials(from: "").isEmpty)
    }

    @Test("Picks a stable avatar gradient")
    func picksAvatarGradient() {
        #expect(avatarGradient(for: "user_me") == avatarGradient(for: "user_me"))
        #expect(avatarGradient(for: "user_me").count == 2)
        #expect(avatarGradient(for: "").count == 2)
    }

    @Test("Detects emoji-only text")
    func detectsEmoji() {
        #expect("😀".isOnlyEmojis)
        #expect("😀🎉".isOnlyEmojis)
        #expect("😀 hi".isOnlyEmojis == false)
        #expect("".isOnlyEmojis == false)
        #expect("😀".isSingleEmoji)
        #expect("😀🎉".isSingleEmoji == false)
        #expect("a".isSingleEmoji == false)
    }

    @Test("Trims whitespace and newlines")
    func trimsText() {
        #expect("  hi \n".trim() == "hi")
        #expect("hi".trim() == "hi")
    }
}
