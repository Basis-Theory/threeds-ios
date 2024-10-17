//
//  ViewController.swift
//  ThreeDSTester
//
//  Created by kevin on 18/9/24.
//

import OSLog
import ThreeDS
import UIKit

enum ThreeDSError: Error {
    case missingSessionId
}

class ViewController: UIViewController, UITextFieldDelegate {
    private var threeDSService: ThreeDSService!
    private var sessionId: String? = nil

    @objc func createThreeDsSession() {
        Task {
            do {
                let session = try await self.threeDSService.createSession(
                    tokenId: textFieldContent)
                sessionId = session.id
                resultLabel.text = "3DS Session created"
            } catch {
                errorLabel.text = "\(error.localizedDescription)"
            }
        }
    }

    @objc func startChallenge() {
        Task {
            do {
                guard let sessionId = sessionId else {
                    throw ThreeDSError.missingSessionId
                }

                try await self.threeDSService.startChallenge(
                    sessionId: sessionId, viewController: self,
                    onCompleted: { result in
                        DispatchQueue.main.async {
                            self.resultLabel.text = "Challenge \(result.status)"
                        }
                        guard let details = result.details else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.detailsLabel.text = "\(details)"
                        }
                    },
                    onFailure: { result in
                        DispatchQueue.main.async {
                            self.resultLabel.text = "Challenge \(result.status)"
                        }
                    })
            } catch {
                errorLabel.text = error.localizedDescription
            }
        }
    }

    @objc func clearState() {
        sessionId = nil

        for view in self.view.subviews {
            if let textField = view as? UITextField {
                textField.text = ""
            }
        }
        
        resultLabel.text = ""
        detailsLabel.text = ""
        errorLabel.text = ""
        
    }

    @objc func getChallengeResult() {
        Task {
            do {
                let endpoint = URL(string: "http://localhost:3333/3ds/get-result")!

                let jsonBody: [String: String] = [
                    "sessionId": sessionId!
                ]

                let requestBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])

                var request = URLRequest(url: endpoint)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = requestBody

                let (data, _) = try await URLSession.shared.data(for: request)

                OSLogger.log("\(data)")

                let decodedResponse = try JSONDecoder().decode(ChallengeResult.self, from: data)

                resultLabel.text = "\(decodedResponse.authenticationStatus)"

                guard let reason = decodedResponse.authenticationStatusReason else {
                    OSLogger.log("No authentication reason")
                    return
                }

                detailsLabel.text = reason

            } catch {
                errorLabel.text = error.localizedDescription
            }
        }
    }

    func createSessionButton() {
        let button = UIButton(type: .system)
        button.setTitle("Create Session", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10

        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])

        button.addTarget(self, action: #selector(createThreeDsSession), for: .touchUpInside)
    }

    func startChallengeButton() {
        let button = UIButton(type: .system)
        button.setTitle("Start Challenge", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10

        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 50),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])

        button.addTarget(self, action: #selector(startChallenge), for: .touchUpInside)
    }

    func getChallengeResultButton() {
        let button = UIButton(type: .system)
        button.setTitle("Get Challenge Result", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10

        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 100),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])

        button.addTarget(self, action: #selector(getChallengeResult), for: .touchUpInside)
    }

    func clearButton() {
        let button = UIButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10

        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 150),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])

        button.addTarget(self, action: #selector(clearState), for: .touchUpInside)
    }

    var textFieldContent: String = ""

    func tokenIdInputField() {
        let textField: UITextField = {
            let tf = UITextField()
            tf.inputView = UIView()
            tf.borderStyle = .roundedRect
            tf.placeholder = "Token ID"
            tf.translatesAutoresizingMaskIntoConstraints = false
            return tf
        }()

        textField.delegate = self

        view.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -250),
            textField.widthAnchor.constraint(equalToConstant: 200),
            textField.heightAnchor.constraint(equalToConstant: 40),
        ])

    }

    let heading: UILabel = {
        let label = UILabel()
        label.text = "3DS"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
        return label
    }()

    let resultLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
        return label
    }()

    let detailsLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
        return label
    }()

    let errorLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(heading)
        self.view.addSubview(resultLabel)
        self.view.addSubview(detailsLabel)
        self.view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            heading.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heading.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -300),
        ])

        NSLayoutConstraint.activate([
            resultLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            resultLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 300),
            resultLabel.widthAnchor.constraint(equalToConstant: 250),
            resultLabel.heightAnchor.constraint(equalToConstant: 50),
        ])

        NSLayoutConstraint.activate([
            detailsLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            detailsLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 350),
            detailsLabel.widthAnchor.constraint(equalToConstant: 250),
            detailsLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 400),
            errorLabel.widthAnchor.constraint(equalToConstant: 250),
            errorLabel.heightAnchor.constraint(equalToConstant: 50),
        ])

        do {
            tokenIdInputField()

            createSessionButton()

            startChallengeButton()

            clearButton()

            getChallengeResultButton()

            guard let apiKey = Configuration.getConfiguration().btPubApiKey else {
                throw ConfigurationInitializationError.keyNotFound
            }

            threeDSService = try ThreeDSService.builder()
                .withSandbox()
                .withApiKey(apiKey)
                .withBaseUrl("api.flock-dev.com")
                .withAuthenticationEndpoint("http://localhost:3333/3ds/authenticate")
                .build()

            Task {
                try await threeDSService.initialize { [weak self] warnings in
                    DispatchQueue.main.async {
                        if let warnings = warnings, !warnings.isEmpty {
                            let messages = warnings.map { $0.message }.joined(separator: "\n")

                            self?.resultLabel.text = messages
                        } else {
                            self?.resultLabel.text = "No warnings."
                        }
                    }
                }
            }

        } catch {
            errorLabel.text = "\(error)"
            OSLogger.log("\(error)")
        }

    }

    func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if let text = textField.text as NSString? {
            let updatedText = text.replacingCharacters(in: range, with: string)
            textFieldContent = updatedText
        }
        return true
    }

}

enum OSLogger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    private static let sdk = OSLog(subsystem: subsystem, category: "sdk")

    static func log(_ text: String, type: OSLogType = .default) {
        os_log("%@", log: OSLogger.sdk, type: type, text)
    }
}

struct ChallengeResult: Encodable, Decodable {
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
    let purchaseAmount: String?
    let merchantName: String?
    let currency: String?
    let acsChallengeMandated: String?
    let authenticationChallengeType: String?
    let authenticationStatusReason: String?
    let acsSignedContent: String?
    let messageExtensions: [String]
    let acsRenderingType: AcsRenderingType?
}

struct AcsRenderingType: Codable {
    let acsInterface: String
    let acsUiTemplate: String
}
