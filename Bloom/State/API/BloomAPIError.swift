//
//  BloomAPIError.swift
//  Bloom
//

import Foundation

enum BloomAPIError: LocalizedError {
    case missingPayload
    case unavailable
    case missingStorage
    case clientUnavailable

    var errorDescription: String? {
        switch self {
        case .missingPayload: return "Backend returned no payload."
        case .unavailable: return "Backend is unavailable in this app mode."
        case .missingStorage: return "App storage is not available."
        case .clientUnavailable: return "Failed to start the messaging client."
        }
    }
}
