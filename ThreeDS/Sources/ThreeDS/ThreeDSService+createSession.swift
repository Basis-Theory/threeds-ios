//
//  ThreeDSService+createSession.swift
//  ThreeDS
//
//  Created by kevin on 9/10/24.
//
import Foundation
import Ravelin3DS

@available(iOS 15.0, *)
extension ThreeDSService {
    public func createSession(
        tokenId: String
    ) async throws -> CreateThreeDsSessionResponse {
        let session = try await _createSession(tokenId: tokenId)

        self.transaction = try service.createTransaction(
            directoryServerID: session.directoryServerId,
            messageVersion: session.recommendedVersion)

        let authRequestParams = try self.transaction.getAuthenticationRequestParameters()

        let updatedSession = try await _updateSession(
            authRequestParams: authRequestParams, sessionId: session.id)

        return updatedSession
    }

    func _createSession(
        tokenId: String
    ) async throws -> CreateThreeDsSessionResponse {
        let jsonBody: [String: String] = [
            "pan": tokenId,
            "device": "app",
        ]

        let requestBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])

        guard let createSessionEndpoint = URL(string: "https://\(apiBaseUrl)/3ds/sessions") else {
            throw ThreeDSServiceError.invalidURL
        }

        return try await makeRequest(
            url: createSessionEndpoint,
            method: "POST",
            body: requestBody,
            expectedStatusCodes: [200, 201]
        )
    }

    func _updateSession(
        authRequestParams: AuthenticationRequestParameters, sessionId: String
    )
        async throws -> CreateThreeDsSessionResponse
    {
        let updateSessionRequestPayload = UpdateThreeDsSessionRequest(
            deviceInfo: ThreeDSDeviceInfo(
                sdkTransactionId: authRequestParams.getSDKTransactionID(),
                sdkApplicationId: authRequestParams.getSDKAppID(),
                sdkEncryptionData: authRequestParams.getDeviceData(),
                sdkEphemeralPublicKey: authRequestParams.getSDKEphemeralPublicKey(),
                sdkMaxTimeout: "05",  // 5 minutes seems to be default
                sdkReferenceNumber: authRequestParams.getSDKReferenceNumber(),
                sdkRenderOptions: ThreeDSMobileSdkRenderOptions(
                    sdkInterface: RenderOptions.native.toRavelinCode(),
                    sdkUiType: [
                        UiTypes.textField.toRavelinCode(),
                        UiTypes.singleSelectField.toRavelinCode(),
                        UiTypes.multiSelectField.toRavelinCode(),
                        UiTypes.oob.toRavelinCode(),
                    ]
                )
            )
        )

        let payload = try JSONEncoder().encode(updateSessionRequestPayload)

        guard
            let updateSessionEndpoint = URL(
                string: "https://\(apiBaseUrl)/3ds/sessions/\(sessionId)")
        else {
            throw ThreeDSServiceError.invalidURL
        }

        return try await makeRequest(
            url: updateSessionEndpoint,
            method: "PUT",
            body: payload,
            expectedStatusCodes: [200]
        )
    }
}
