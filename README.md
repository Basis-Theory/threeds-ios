# Basis Theory iOS 3DS SDK

## Installation

To add the Basis Theory iOS package using [Swift Package Manager](https://www.swift.org/package-manager/), open XCode and click on `File → Add Packages`, search for "https://github.com/Basis-Theory/3ds-ios", and click on `Copy Dependency`.

## Usage

**⚠️ Code for illustration purposes ⚠️**

```swift
class ViewController: UIViewController {
    private var threeDSService: ThreeDSService!

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            do {
                threeDSService = try ThreeDSService.builder()
                    .withApiKey("<YOUR PUBLIC API KEY>")
                    .withAuthenticationEndpoint("<YOUR AUTHENTICATION ENDPOINT>")
                    .build()

                try await threeDSService.initialize { [weak self] warnings in
                        if let warnings = warnings, !warnings.isEmpty {
                            let messages = warnings.map { $0.message }.joined(separator: "\n")

                            print(messages)
                        } else {
                            print("No warnings.")
                        }
                }

                let session = try await threeDSService.createSession(tokenId: "<CARD TOKEN ID>")

                try await threeDSService.startChallenge(sessionId: session.id, viewController: self,
                    onCompleted: { result in
                        print("Challenge \(result.status)")

                        guard let details = result.details else {
                            return
                        }

                        print(details)
                    },
                    onFailure: { [self] result in
                        print("Challenge \(result.status)")
                    })

                print(session.id)

            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
```
