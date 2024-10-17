//
//  Configuration.swift
//  ThreeDSTester
//
//  Created by kevin on 10/10/24.
//

import Foundation

struct EnvConfig: Decodable {
    let btPubApiKey: String?

    init() {
        self.btPubApiKey = nil
    }
}

enum ConfigurationInitializationError: Error, LocalizedError {
    case envPlistNotFound
    case unableToReadEnvPlist
    case keyNotFound
}

class Configuration {
    static public func getConfiguration() -> EnvConfig {
        do {
            let url = Bundle(for: Configuration.self).path(forResource: "Env", ofType: "plist")

            guard let url = url else {
                throw ConfigurationInitializationError.envPlistNotFound
            }

            let data = FileManager.default.contents(atPath: url)

            guard let data else {
                throw ConfigurationInitializationError.unableToReadEnvPlist
            }

            return try PropertyListDecoder().decode(EnvConfig.self, from: data)
        } catch {
            print(error)
        }

        return EnvConfig()
    }
}
