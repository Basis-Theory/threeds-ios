//
//  ViewController.swift
//  ThreeDSTester
//
//  Created by kevin on 18/9/24.
//

import UIKit
import ThreeDS

class ViewController: UIViewController {
    private var threeDS: ThreeDS!
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        do {
            threeDS = try ThreeDS.builder()
                .withSandbox()
                .withApiKey("")
                .withAuthenticationEndpoint("")
                .build()
            
     
            Task {
                try await threeDS.initialize() { [weak self] warnings in
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
            

        } catch {
            
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
        toastLabel.numberOfLines = 0 // Allow for multi-line
        toastLabel.lineBreakMode = .byWordWrapping
        
         let maxWidth = self.view.frame.size.width - 40
        let constrainedSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let expectedSize = toastLabel.sizeThatFits(constrainedSize)
        
        toastLabel.frame = CGRect(x: self.view.frame.size.width / 2 - expectedSize.width / 2,
                                  y: self.view.frame.size.height - 100,
                                  width: expectedSize.width + 20,
                                  height: expectedSize.height + 20)
        
        self.view.addSubview(toastLabel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            toastLabel.removeFromSuperview()
        }
    }
}
