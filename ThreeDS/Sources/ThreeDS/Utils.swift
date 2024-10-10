//
//  ChallengeViewImplementation.swift
//  ThreeDS
//
//  Created by kevin on 9/10/24.
//
import Ravelin3DS

class ChallengeViewImplementation: ChallengeView {
    private(set) var viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
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

internal struct UpdateThreeDsSessionRequest: Codable {
    let deviceInfo: ThreeDSDeviceInfo

    enum CodingKeys: String, CodingKey {
        case deviceInfo = "device_info"
    }
}

internal struct ThreeDSDeviceInfo: Codable {
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

internal struct ThreeDSMobileSdkRenderOptions: Codable {
    var sdkInterface: String?
    var sdkUiType: [String]?

    enum CodingKeys: String, CodingKey {
        case sdkInterface = "sdk_interface"
        case sdkUiType = "sdk_ui_type"
    }
}

internal enum RenderOptions: String {
    case native = "01"

    func toRavelinCode() -> String {
        return self.rawValue
    }
}

internal enum UiTypes: String {
    case textField = "01"
    case singleSelectField = "02"
    case multiSelectField = "03"
    case oob = "04"

    func toRavelinCode() -> String {
        return self.rawValue
    }
}

internal enum RegionEnum {
    case EU, US
}

internal struct AuthenticationResponse: Codable {
    let panTokenId: String
    let threedsVersion: String
    let acsTransactionId: String
    let dsTransactionId: String
    let sdkTransactionId: String
    let acsReferenceNumber: String
    let dsReferenceNumber: String
    let authenticationValue: String?
    let authenticationStatus: String
    let authenticationStatusCode: String
    let eci: String
    let purchaseAmount: String
    let merchantName: String
    let currency: String?
    let acsChallengeMandated: String?
    let authenticationChallengeType: String?
    let authenticationStatusReason: String?
    let acsSignedContent: String
    let messageExtensions: [String]
    let acsRenderingType: AcsRenderingType?
}

internal struct AcsRenderingType: Codable {
    let acsInterface: String
    let acsUiTemplate: String
}

public struct ChallengeResponse: Codable {
    public let id: String
    public let status: String
    public let details: String?

    init(id: String, status: String, details: String? = nil) {
        self.id = id
        self.status = status
        self.details = details
    }
}

enum ThreeDSServiceError: Error {
    case missingApiKey
    case missingAuthenticationEndpoint
    case invalidResponse
    case invalidURL
    case initializationError
}

