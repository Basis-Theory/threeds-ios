//
//  ViewController.swift
//  ThreeDSTester
//
//  Created by kevin on 18/9/24.
//

import OSLog
import ThreeDS
import UIKit

class ViewController: UIViewController {
    private var threeDSService: ThreeDSService!

    @objc func createThreeDsSession() {
        Task {
            do {
                let session = try await threeDSService.createSession(
                    tokenId: "72cb3d3a-a1c0-4d47-99ce-447c028ff212")

                OSLogger.log("Session created: \(session)")

                let alert = UIAlertController(
                    title: "Session created",
                    message: "Session ID: \(session.id)",
                    preferredStyle: .alert)

                alert.addAction(
                    UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)

            } catch {
                print("\(error) -> \(error.localizedDescription)")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            threeDSService = try ThreeDSService.builder()
                .withSandbox()
                .withApiKey("key_dev_prod_us_pub_JU4qttr2YJxLJqg64S4Tf5")
                .withBaseUrl("api.flock-dev.com")
                .withAuthenticationEndpoint("")
                .build()

            Task {
                try await threeDSService.initialize { [weak self] warnings in
                    DispatchQueue.main.async {
                        if let warnings = warnings, !warnings.isEmpty {
                            let messages = warnings.map { $0.message }.joined(separator: "\n")

                            let alert = UIAlertController(
                                title: "Warning!",
                                message: messages,
                                preferredStyle: .alert)
                            alert.addAction(
                                UIAlertAction(title: "OK", style: .default, handler: nil))
                            self?.present(alert, animated: true, completion: nil)
                        } else {
                            self?.showToast(message: "No warnings.")
                        }
                    }
                }
            }

            let button = UIButton(type: .system)
            button.setTitle("Create 3DS Session", for: .normal)
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

        } catch {
            // error handling
        }

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
