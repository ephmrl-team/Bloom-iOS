//
//  StorageUsage.swift
//  Bloom
//

import Foundation

struct StorageUsage: Equatable, Sendable {
    var documents: Int64 = 0
    var temporary: Int64 = 0

    var total: Int64 {
        documents + temporary
    }

    var formattedDocuments: String {
        Self.format(documents)
    }

    var formattedTemporary: String {
        Self.format(temporary)
    }

    var formattedTotal: String {
        Self.format(total)
    }

    static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        // "Zero KB" reads as a bug in a storage row; show "0 KB" instead.
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: bytes)
    }
}

/// Measures and clears the app's own Documents and tmp directories off the main actor.
enum StorageUsageReader {
    nonisolated static func read() async -> StorageUsage {
        await Task.detached(priority: .utility) {
            let manager = FileManager.default
            return StorageUsage(
                documents: size(of: manager.urls(for: .documentDirectory, in: .userDomainMask).first, manager: manager),
                temporary: size(of: manager.temporaryDirectory, manager: manager)
            )
        }.value
    }

    nonisolated static func clearTemporary() async {
        await Task.detached(priority: .utility) {
            let manager = FileManager.default
            let contents = (try? manager.contentsOfDirectory(
                at: manager.temporaryDirectory,
                includingPropertiesForKeys: nil
            )) ?? []
            for item in contents {
                try? manager.removeItem(at: item)
            }
        }.value
    }

    private nonisolated static func size(of url: URL?, manager: FileManager) -> Int64 {
        guard let url else { return 0 }

        let keys: [URLResourceKey] = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        guard let enumerator = manager.enumerator(at: url, includingPropertiesForKeys: keys) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true
            else { continue }
            total += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return total
    }
}
