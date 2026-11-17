//
//  FormattingTests.swift
//  Bloom
//

@testable import Bloom
import Testing
import UIKit

@Suite("Formatting helpers")
struct FormattingTests {
    private struct Components {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
    }

    private func components(_ color: UIColor) -> Components {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return Components(red: red, green: green, blue: blue, alpha: alpha)
    }

    private func expectColor(_ hex: String, _ expected: Components) {
        let actual = components(UIColor(hex: hex))
        #expect(abs(actual.red - expected.red) < 0.01)
        #expect(abs(actual.green - expected.green) < 0.01)
        #expect(abs(actual.blue - expected.blue) < 0.01)
        #expect(abs(actual.alpha - expected.alpha) < 0.01)
    }

    private func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> Components {
        Components(red: red, green: green, blue: blue, alpha: alpha)
    }

    @Test("Parses six digit hex colours")
    func parsesSixDigits() {
        expectColor("#1A8CFF", rgba(26 / 255, 140 / 255, 1, 1))
        expectColor("000000", rgba(0, 0, 0, 1))
        expectColor("FFFFFF", rgba(1, 1, 1, 1))
    }

    @Test("Parses three digit and eight digit hex colours")
    func parsesShortAndAlphaHex() {
        expectColor("#fff", rgba(1, 1, 1, 1))
        expectColor("#f00", rgba(1, 0, 0, 1))
        expectColor("FF000080", rgba(1, 0, 0, 128 / 255))
    }

    @Test("Falls back to white for an unsupported length")
    func fallsBackToWhite() {
        expectColor("", rgba(1, 1, 1, 1))
        expectColor("#12345", rgba(1, 1, 1, 1))
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
