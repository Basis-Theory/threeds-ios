//
//  ThreeDSService+makeRequest.swift
//  ThreeDS
//
//  Created by kevin on 9/10/24.
//
import Foundation

@available(iOS 15.0, *)
extension ThreeDSService {
    func makeRequest<T: Codable>(
        url: URL,
        method: String,
        body: Data?,
        expectedStatusCodes: [Int] = [200, 201]
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(self.apiKey, forHTTPHeaderField: "BT-API-KEY")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
            expectedStatusCodes.contains(httpResponse.statusCode)
        else {
            throw ThreeDSServiceError.invalidResponse((response as? HTTPURLResponse)!.statusCode)
        }

        let decodedResponse = try self.decoder.decode(T.self, from: data)
        
        return decodedResponse
    }
}
