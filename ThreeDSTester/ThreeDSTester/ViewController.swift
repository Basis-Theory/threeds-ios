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
                showToast(message: "3DS Session created")
            } catch {
                print("\(error) -> \(error.localizedDescription)")
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
                        self.showToast(message: "Challenge \(result.status)")
                        
                        guard let details = result.details else {
                            return
                        }
                        
                        self.showToast(message: "\(details)")
                    },
                    onFailure: { result in self.showToast(message: "Challenge \(result.status)")
                    })
            } catch {
                print("\(error) -> \(error.localizedDescription)")
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

                let decodedResponse = try JSONDecoder().decode(ChallengeResult.self, from: data)

                print(decodedResponse.authenticationStatus)

                self.showToast(message: "\(decodedResponse.authenticationStatus)")

            } catch {

                print("\(error) -> \(error.localizedDescription)")
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
            tf.borderStyle = .roundedRect
            tf.placeholder = "Token ID"
            tf.translatesAutoresizingMaskIntoConstraints = false
            return tf
        }()

        textField.delegate = self

        view.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -300),
            textField.widthAnchor.constraint(equalToConstant: 200),
            textField.heightAnchor.constraint(equalToConstant: 40),
        ])

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        

        do {
            guard let apiKey = Configuration.getConfiguration().btPubApiKey else {
                throw "Could not find API Key"
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

                            self?.showToast(message: messages)
                        } else {
                            self?.showToast(message: "No warnings.")
                        }
                    }
                }
            }

            let textfield = tokenIdInputField()

            createSessionButton()

            startChallengeButton()

            clearButton()

            getChallengeResultButton()

        } catch {
            // error handling
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

extension UIViewController {

    func showToast(message: String, font: UIFont = .systemFont(ofSize: 16.0)) {
        DispatchQueue.main.async {
            let toastLabel = UILabel()
            toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            toastLabel.textColor = UIColor.white
            toastLabel.textAlignment = .center
            toastLabel.font = font
            toastLabel.text = message
            toastLabel.alpha = 1.0
            toastLabel.layer.cornerRadius = 10
            toastLabel.clipsToBounds = true
            toastLabel.numberOfLines = 0
            toastLabel.lineBreakMode = .byWordWrapping

            let maxWidth = self.view.frame.size.width - 40
            let constrainedSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
            let expectedSize = toastLabel.sizeThatFits(constrainedSize)

            toastLabel.frame = CGRect(
                x: self.view.frame.size.width / 2 - expectedSize.width / 2,
                y: self.view.frame.size.height - 100,
                width: expectedSize.width + 20,
                height: expectedSize.height + 20)

            self.view.addSubview(toastLabel)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                toastLabel.removeFromSuperview()
            }
        }
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
    let authenticationValue: String
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
