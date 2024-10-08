import Foundation
import OSLog
import Ravelin3DS

@available(iOS 15.0, *)
public class ThreeDSService {
    private var apiKey: String
    private let region: String
    private let locale: String
    private let sandbox: Bool
    private let authenticationEndpoint: String

    private var apiBaseUrl: String = "api.basistheory.com"
    private var service: ThreeDS2Service!
    private var transaction: Transaction!
    private let decoder = JSONDecoder()

    public init(
        apiKey: String, region: String, locale: String, sandbox: Bool, apiBaseUrl: String,
        authenticationEndpoint: String
    ) {
        self.apiKey = apiKey
        self.region = region
        self.locale = locale
        self.sandbox = sandbox
        self.apiBaseUrl = apiBaseUrl
        self.authenticationEndpoint = authenticationEndpoint

        service = ThreeDS2SDK()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    public static func builder() -> ThreeDSServiceBuilder {
        return ThreeDSServiceBuilder()
    }
}

@available(iOS 15.0, *)
public class ThreeDSServiceBuilder {
    private let regionMap: [RegionEnum: String] = [.EU: "EuLive", .US: "USLive"]
    private var apiKey: String?
    private var region: String
    private var locale: String?
    private var sandbox: Bool = false
    private var authenticationEndpoint: String?
    private var apiBaseUrl: String = "api.basistheory.com"

    init() {
        self.region = regionMap[.EU]!  // Default to EU
    }

    @discardableResult
    public func withApiKey(_ apiKey: String) -> ThreeDSServiceBuilder {
        self.apiKey = apiKey
        return self
    }

    @discardableResult
    public func withAuthenticationEndpoint(_ authenticationEndpoint: String)
        -> ThreeDSServiceBuilder
    {
        self.authenticationEndpoint = authenticationEndpoint
        return self
    }

    @discardableResult
    public func withLocale(_ _locale: String?) -> ThreeDSServiceBuilder {
        self.locale = _locale
        return self
    }

    @discardableResult
    public func withSandbox() -> ThreeDSServiceBuilder {
        self.sandbox = true
        return self
    }

    /***
     ** Internal use only*
     **/
    @discardableResult
    public func withBaseUrl(_ apiBaseUrl: String) -> ThreeDSServiceBuilder {
        assert(apiBaseUrl == "api.flock-dev.com", "Invalid base URL")
        self.apiBaseUrl = apiBaseUrl
        return self
    }

    public func build() throws -> ThreeDSService {
        guard let apiKey = apiKey else {
            throw ThreeDsServiceError.missingApiKey
        }
        guard let authenticationEndpoint = authenticationEndpoint else {
            throw ThreeDsServiceError.missingAuthenticationEndpoint
        }

        let localeOrDefault: String =
            locale != nil
            ? locale!
            : (NSLocale.autoupdatingCurrent.languageCode ?? "en") + "-"
                + (NSLocale.autoupdatingCurrent.regionCode ?? "US")

        return ThreeDSService(
            apiKey: apiKey,
            region: region,
            locale: localeOrDefault,
            sandbox: sandbox,
            apiBaseUrl: apiBaseUrl,
            authenticationEndpoint: authenticationEndpoint
        )
    }
}

enum ThreeDsServiceError: Error {
    case missingApiKey
    case missingAuthenticationEndpoint
    case invalidResponse
    case invalidURL
    case initializationError
}

enum RegionEnum {
    case EU, US
}

enum OSLogger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    private static let sdk = OSLog(subsystem: subsystem, category: "sdk")

    static func log(_ text: String, type: OSLogType = .default) {
        os_log("%@", log: OSLogger.sdk, type: type, text)
    }
}

public struct ThreeDSWarning {
    public let message: String
}

struct RavelinKeys: Codable {
    let test: String
    let live: String
}

public struct CreateThreeDsSessionResponse: Decodable, Encodable, Sendable {
    public let id: String
    public let methodUrl: String
    public let cardBrand: String
    public let methodNotificationUrl: String
    public let directoryServerId: String
    public let recommendedVersion: String
}

struct UpdateThreeDsSessionRequest: Codable {
    let deviceInfo: ThreeDSDeviceInfo

    enum CodingKeys: String, CodingKey {
        case deviceInfo = "device_info"
    }
}

struct ThreeDSDeviceInfo: Codable {
    var sdkTransactionId: String?
    var sdkApplicationId: String?
    var sdkEncryptionData: String?
    var sdkEphemeralPublicKey: String?
    var sdkMaxTimeout: String?
    var sdkReferenceNumber: String?
    var sdkRenderOptions: ThreeDSMobileSdkRenderOptions?

    enum CodingKeys: String, CodingKey {
        case sdkTransactionId = "sdk_transaction_id"
        case sdkApplicationId = "sdk_application_id"
        case sdkEncryptionData = "sdk_encryption_data"
        case sdkEphemeralPublicKey = "sdk_ephemeral_public_key"
        case sdkMaxTimeout = "sdk_max_timeout"
        case sdkReferenceNumber = "sdk_reference_number"
        case sdkRenderOptions = "sdk_render_options"
    }
}

struct ThreeDSMobileSdkRenderOptions: Codable {
    var sdkInterface: String?
    var sdkUiType: [String]?

    enum CodingKeys: String, CodingKey {
        case sdkInterface = "sdk_interface"
        case sdkUiType = "sdk_ui_type"
    }
}

enum RenderOptions: String {
    case native = "01"

    func toRavelinCode() -> String {
        return self.rawValue
    }
}

enum UiTypes: String {
    case textField = "01"
    case singleSelectField = "02"
    case multiSelectField = "03"
    case oob = "04"

    func toRavelinCode() -> String {
        return self.rawValue
    }
}

@available(iOS 15.0, *)
// Initialization
extension ThreeDSService {
    @MainActor
    public func initialize(completion: @escaping ([ThreeDSWarning]?) -> Void) async throws {
        let endpoint = "https://cdn.basistheory.com/keys/3ds.json"

        guard let url = URL(string: endpoint) else {
            throw ThreeDsServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw ThreeDsServiceError.invalidResponse
        }

        let keys = try decoder.decode(RavelinKeys.self, from: data)

        let configParameters = ConfigParameters()
        try configParameters.addParam(
            paramType: .publishableApiKey,
            paramValue: sandbox ? keys.test : keys.live)

        do {
            // TODO: rewrite to use async/await(?)
            try service.initialize(
                configParameters: configParameters, locale: locale, uiCustomization: nil
            ) { success in
                guard success else {
                    completion(nil)
                    return
                }

                do {
                    let warnings: [ThreeDSWarning] = try self.service.getWarnings().map {
                        ThreeDSWarning(message: $0.getMessage())
                    }

                    completion(warnings)
                } catch {
                    completion(nil)
                }
            }
        } catch {
            throw ThreeDsServiceError.initializationError
        }
    }
}

@available(iOS 15.0, *)
extension ThreeDSService {
    private func makeRequest<T: Codable>(
        url: URL,
        method: String,
        body: Data?,
        expectedStatusCodes: [Int] = [200, 201]
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "BT-API-KEY")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            expectedStatusCodes.contains(httpResponse.statusCode)
        else {
            throw ThreeDsServiceError.invalidResponse
        }

        let decodedResponse = try decoder.decode(T.self, from: data)

        print(decodedResponse)

        return decodedResponse
    }
}

@available(iOS 15.0, *)
extension ThreeDSService {
    public func startChallenge(
        sessionId: String, viewController: UIViewController,
        onCompleted: @escaping (ChallengeResponse) -> Void,
        onFailure: @escaping (ChallengeResponse) -> Void
    ) async throws {
        var authenticationResponse = try await authenticateSession(sessionId: sessionId)

        if authenticationResponse.authenticationStatus == "challenge" {
            var params = ChallengeParameters()
            params.set3DSServerTransactionID(sessionId)
            params.setAcsTransactionID(authenticationResponse.acsTransactionId)
            params.setAcsRefNumber(authenticationResponse.acsReferenceNumber)
            params.setAcsSignedContent(authenticationResponse.acsSignedContent)
            params.setThreeDSRequestorAppURL(
                "https://www.ravelin.com/?transID=\(try transaction.getAuthenticationRequestParameters().getSDKTransactionID())"
            )

            let challengeStatusReceiver = ChallengeHandler(
                sessionId: sessionId,
                authenticationResponse: authenticationResponse,
                onCompleted: onCompleted,
                onFailure: onFailure)

            try transaction.doChallenge(
                challengeParameters: params,
                challengeStatusReceiver: challengeStatusReceiver,
                timeOut: 5,
                challengeView: ChallengeViewImplementation(viewController: viewController))
        }

    }

    func authenticateSession(sessionId: String) async throws -> AuthenticationResponse {
        let jsonBody: [String: String] = [
            "sessionId": sessionId
        ]

        let requestBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])

        guard let authenticationEndpoint = URL(string: self.authenticationEndpoint) else {
            throw ThreeDsServiceError.invalidURL
        }

        return try await makeRequest(
            url: authenticationEndpoint,
            method: "POST",
            body: requestBody,
            expectedStatusCodes: [200]
        )
    }
}

@available(iOS 15.0, *)
extension ThreeDSService {
    public func createSession(
        tokenId: String
    ) async throws -> CreateThreeDsSessionResponse {
        let _token = "\(tokenId)"
        let session = try await _createSession(tokenId: _token)

        self.transaction = try service.createTransaction(
            directoryServerID: session.directoryServerId,
            messageVersion: session.recommendedVersion)

        let authRequestParams = try await self.transaction.getAuthenticationRequestParameters()

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
            throw ThreeDsServiceError.invalidURL
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
            throw ThreeDsServiceError.invalidURL
        }

        return try await makeRequest(
            url: updateSessionEndpoint,
            method: "PUT",
            body: payload,
            expectedStatusCodes: [200]
        )
    }
}

struct AuthenticationResponse: Codable {
    let panTokenId: String
    let threedsVersion: String
    let acsTransactionId: String
    let dsTransactionId: String
    let sdkTransactionId: String
    let acsReferenceNumber: String
    let dsReferenceNumber: String
    let authenticationValue: String? = nil
    let authenticationStatus: String
    let authenticationStatusCode: String
    let eci: String = ""
    let purchaseAmount: String
    let merchantName: String
    let currency: String?
    let acsChallengeMandated: String? = nil
    let authenticationChallengeType: String? = nil
    let authenticationStatusReason: String? = nil
    let acsSignedContent: String
    let messageExtensions: [String] = []
    let acsRenderingType: AcsRenderingType? = nil
}

struct AcsRenderingType: Codable {
    let acsInterface: String
    let acsUiTemplate: String
}

class ChallengeViewImplementation: ChallengeView {
    private(set) var viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }
}

class ChallengeHandler: ChallengeStatusReceiver {

    let sessionId: String
    let authenticationResponse: AuthenticationResponse
    let transactionStatusMap = [
        "Y": "successful",
        "A": "attempted",
        "N": "failed",
        "U": "unavailable",
        "R": "rejected",
    ]
    let onCompleted: (ChallengeResponse) -> Void
    let onFailure: (ChallengeResponse) -> Void

    init(
        sessionId: String,
        authenticationResponse: AuthenticationResponse,
        onCompleted: @escaping (ChallengeResponse) -> Void,
        onFailure: @escaping (ChallengeResponse) -> Void
    ) {
        self.sessionId = sessionId
        self.authenticationResponse = authenticationResponse
        self.onCompleted = onCompleted
        self.onFailure = onFailure
    }

    func completed(completionEvent: CompletionEvent) {
        if let transactionStatus = transactionStatusMap[try completionEvent.getTransactionStatus()]
        {
            OSLogger.log("challenge completed with status: \(transactionStatus)")
            onCompleted(
                ChallengeResponse(
                    id: sessionId,
                    status: transactionStatus,
                    details: authenticationResponse.authenticationStatusReason
                )
            )
        } else {
            OSLogger.log("challenge failed successfully")
        }
        closeTransaction()
    }

    func cancelled() {
        closeTransaction()
        OSLogger.log("challenge cancelled")
        onFailure(
            ChallengeResponse(
                id: sessionId,
                status: "N",
                details: "Challenge cancelled"))
    }

    func timedout() {
        closeTransaction()
        OSLogger.log("challenge timed out")
        onFailure(
            ChallengeResponse(
                id: sessionId,
                status: "N",
                details: "Challenge timed out"))
    }

    func protocolError(protocolErrorEvent: ProtocolErrorEvent) {
        closeTransaction()
        OSLogger.log("challenge protocol error: \(protocolErrorEvent.getErrorMessage())")
        onFailure(
            ChallengeResponse(
                id: sessionId,
                status: "N",
                details: "ProtocolError \(protocolErrorEvent.getErrorMessage())"
            )
        )
    }

    func runtimeError(runtimeErrorEvent: RuntimeErrorEvent) {
        closeTransaction()
        OSLogger.log("challenge runtime error: \(runtimeErrorEvent.getErrorMessage())")
        onFailure(
            ChallengeResponse(
                id: sessionId,
                status: "N",
                details: "RuntimeError \(runtimeErrorEvent.getErrorMessage())"
            )
        )
    }

    private func closeTransaction() {
        // close the transaction
    }
}

public struct ChallengeResponse: Codable {
    let id: String
    let status: String
    let details: String?

    init(id: String, status: String, details: String? = nil) {
        self.id = id
        self.status = status
        self.details = details
    }
}
