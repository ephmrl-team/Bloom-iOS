//
//  Eventually.swift
//  Bloom
//

import Foundation

/// Polls a condition across task yields, for state that settles in a detached task.
func eventually(_ condition: () -> Bool) async -> Bool {
    for _ in 0..<200 {
        if condition() { return true }
        await Task.yield()
    }
    return condition()
}
