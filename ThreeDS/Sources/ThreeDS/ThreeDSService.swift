import Foundation
import Ravelin3DS

import OSLog


@available(iOS 15.0, *)
public class ThreeDS {
    private var apiKey: String
    private let region: String
    private let locale: String
    private let sandbox: Bool
    private let authenticationEndpoint: String
    
    private var apiBaseUrl: String = "api.basistheory.com"
    private var service: ThreeDS2Service!
    
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
    }
    
    public static func builder() -> ThreeDSServiceBuilder {
        return ThreeDSServiceBuilder()
    }
    
    @discardableResult
    public func initialize(completion: @escaping ([ThreeDSWarning]?) -> Void) async throws -> String {
        let endpoint = "https://cdn.basistheory.com/keys/3ds.json"
        
        guard let url = URL(string: endpoint) else {
            OSLogger.log("Invalid URL: \(endpoint)")
            throw ThreeDsServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw ThreeDsServiceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let keys = try decoder.decode(RavelinKeys.self, from: data)
        
        var msg = "initializing"
        service = ThreeDS2SDK()
        
        let configParameters = ConfigParameters()
        try configParameters.addParam(
            paramType: .publishableApiKey,
            paramValue: sandbox ? keys.test : keys.live)
        
        
        do {
            try service.initialize(configParameters: configParameters, locale: locale, uiCustomization: nil) { success in
                guard success else {
                    OSLogger.log("Initialization failed")
                    completion(nil)
                    return
                }
                
                OSLogger.log("Initialize SDK complete")
                
                do {
                    let warnings: [ThreeDSWarning] = try self.service.getWarnings().map {
                        ThreeDSWarning(message: $0.getMessage())
                    }
                    
                    OSLogger.log("\(warnings.map {$0.message}.joined(separator: "\n"))")
                    completion(warnings)
                } catch {
                    OSLogger.log("Error getting warnings: \(error)")
                    completion(nil)
                }
            }
        } catch {
            
        }
        return msg
    }
    
}

@available(iOS 15.0, *)
public class ThreeDSServiceBuilder {
    /** Default to EU, according to Ravelin our account was setup to work in the EU
     ** US is reserved for "big ho ldings" in the US
     **/
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

    public func build() throws -> ThreeDS {
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

        return ThreeDS(
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
