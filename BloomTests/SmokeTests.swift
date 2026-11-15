//
//  SmokeTests.swift
//  Bloom
//

import Testing
@testable import Bloom

@Suite("Smoke")
struct SmokeTests {
    @Test("Test target links against the app module")
    func moduleLoads() {
        #expect(Theme.spacing.md > 0)
    }
}
