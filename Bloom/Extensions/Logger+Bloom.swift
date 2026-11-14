//
//  Logger+Bloom.swift
//  Bloom
//

import Foundation
import OSLog

extension Logger {
    nonisolated static let bloom = Logger(subsystem: "pw.ephmrl.bloom", category: "app")
}
