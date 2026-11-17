//
//  KeychainTests.swift
//  Bloom
//

@testable import Bloom
import Foundation
import Security
import Testing

/// Uses its own service name so a test run never touches real credentials.
@Suite("Keychain", .serialized)
struct KeychainTests {
    private let service = "pw.ephmrl.bloom.tests"
    private let account = "unit-tests"
    private let keychain = KeychainHelper.shared

    private func clear() {
        keychain.delete(service: service, account: account)
    }

    @Test("Stores, overwrites and deletes a value")
    func roundTrip() throws {
        clear()
        defer { clear() }

        #expect(keychain.read(service: service, account: account) == nil)

        try keychain.save("first", service: service, account: account)
        #expect(keychain.read(service: service, account: account) == "first")

        try keychain.save("second", service: service, account: account)
        #expect(keychain.read(service: service, account: account) == "second")

        clear()
        #expect(keychain.read(service: service, account: account) == nil)
    }

    @Test("Keeps items on this device only")
    func accessibility() throws {
        clear()
        defer { clear() }
        try keychain.save("secret", service: service, account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let attributes = result as? [String: Any]

        #expect(status == errSecSuccess)
        let accessible = attributes?[kSecAttrAccessible as String] as? String
        #expect(accessible == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
        #expect(attributes?[kSecAttrSynchronizable as String] as? Bool != true)
    }

    @Test("Reports a missing value instead of failing")
    func missingValue() {
        clear()

        #expect(keychain.read(service: service, account: account) == nil)
    }
}
