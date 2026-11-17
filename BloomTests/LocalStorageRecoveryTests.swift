//
//  LocalStorageRecoveryTests.swift
//  BloomTests
//

@testable import Bloom
import Foundation
import Testing

@Suite("Local storage recovery")
struct LocalStorageRecoveryTests {
    @Test("Recognises an unreadable database")
    func recognisesDatabaseFailure() {
        let error = NSError(
            domain: "BloomKit",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "failed to open encrypted database: sqlite: file is not a database (26)"
            ]
        )

        #expect(BloomKitAPI.isDatabaseFailure(error))
    }

    @Test("Leaves unrelated failures alone")
    func ignoresOtherFailures() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)

        #expect(!BloomKitAPI.isDatabaseFailure(error))
    }

    @Test("Deletes the contents of the storage folder")
    func deletesStorageContents() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let first = folder.appendingPathComponent("bloom.db")
        let second = folder.appendingPathComponent("bloom.db-wal")
        try Data("broken".utf8).write(to: first)
        try Data("broken".utf8).write(to: second)

        BloomKitAPI.resetStorage(at: folder.path)

        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }
}
