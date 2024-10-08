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
                let session = try await threeDSService.createSession(
                    tokenId: textFieldContent)

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

                try await threeDSService.startChallenge(
                    sessionId: sessionId, viewController: self,
                    onCompleted: { result in
                        print("completed \(result)")
                    },
                    onFailure: { result in
                        print("failed \(result)")
                    })
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

    var textFieldContent: String = "" {
        didSet {
            print("TextField content: \(textFieldContent)")
        }
    }

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
            threeDSService = try ThreeDSService.builder()
                .withSandbox()
                .withApiKey("key_dev_prod_us_pub_JU4qttr2YJxLJqg64S4Tf5")
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

            tokenIdInputField()

            createSessionButton()

            startChallengeButton()

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

    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldContent = textField.text ?? ""
    }

}

extension UIViewController {

    func showToast(message: String, font: UIFont = .systemFont(ofSize: 16.0)) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = font
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0  // Allow for multi-line
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            toastLabel.removeFromSuperview()
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
