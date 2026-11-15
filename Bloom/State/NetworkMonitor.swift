//
//  NetworkMonitor.swift
//  Bloom
//

import Foundation
import Network
import Observation

/// Reports whether the device has a network path the app can use.
@Observable
@MainActor
final class NetworkMonitor {
    private(set) var isOnline = true

    @ObservationIgnored private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied
            // The monitor calls back on the queue it was started with, which is the main one.
            MainActor.assumeIsolated {
                self?.isOnline = isOnline
            }
        }
        monitor.start(queue: .main)
    }

    nonisolated deinit {
        monitor.cancel()
    }
}
