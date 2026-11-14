//
//  BloomAPIError.swift
//  Bloom
//

import Foundation

enum BloomAPIError: LocalizedError {
    case missingPayload
    case unavailable

    var errorDescription: String? {
        switch self {
        case .missingPayload: return "Backend returned no payload."
        case .unavailable: return "Backend is unavailable in this app mode."
        }
    }
}
