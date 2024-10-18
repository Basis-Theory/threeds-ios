//
//  ThreeDSServiceError.swift
//  ThreeDS
//
//  Created by kevin on 9/10/24.
//
import Foundation

enum ThreeDSServiceError: Error, LocalizedError {
    case missingApiKey
    case missingAuthenticationEndpoint
    case invalidResponse(Int)
    case invalidURL
    case initializationError
    case sessionCreationError(String)
    case authenticationError(String)

    var errorDescription: String? {
        switch self {
        case .sessionCreationError(let message):
            return "Unable to create session, \(message)"
        case .authenticationError(let message):
            return "Unable to authenticate, \(message)"
        case .invalidResponse(let statusCode):
            return "3DS service responded \(statusCode)"
        default:
            return "An unknown error occurred."
        }
    }
}
