//
//  ThreeDSServiceError.swift
//  ThreeDS
//
//  Created by kevin on 9/10/24.
//


enum ThreeDSServiceError: Error {
    case missingApiKey
    case missingAuthenticationEndpoint
    case invalidResponse
    case invalidURL
    case initializationError
}
