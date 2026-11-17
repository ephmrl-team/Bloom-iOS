//
//  SmokeTests.swift
//  Bloom
//

@testable import Bloom
import Testing

@Suite("Smoke")
struct SmokeTests {
    @Test("Test target links against the app module")
    func moduleLoads() {
        #expect(Theme.spacing.md > 0)
    }
}
