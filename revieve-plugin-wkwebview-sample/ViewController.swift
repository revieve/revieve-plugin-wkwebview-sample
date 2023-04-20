//
//  ViewController.swift
//  revieve-plugin-wkwebview-sample
//
//  Created by Revieve Inc.
//
//  Notes:
//
//    - For the camera to work inside the webview, you'll need to set "Privacy - Camera Usage Description"
//      in your Info.plist and request for camera permissions from the end user
//

import UIKit
import WebKit

struct Revieve {
    // Load the revieve-web-plugin from Revieve's production CDN:
    static let CDN_DOMAIN = "https://d38knilzwtuys1.cloudfront.net"
    // Origin set to *
    static let ORIGIN = "*"
    // Select which Revieve API environment to use. Can be test or prod
    static let ENV = "test"
    // static let PARTNER_ID = "9KpsLizwYK" // skincare demo
    static let PARTNER_ID = "GHru81v4aU" // vto makeup demo
    // PDP VTO trigger example
    static let SHOW_PDP_BUTTON = false
    // Construct the full URL
    static let FULL_URL = URL(string: "\(CDN_DOMAIN)/revieve-plugin-v4/app.html?partnerId=\(PARTNER_ID)&env=\(ENV)&crossOrigin=1&origin=\(ORIGIN)")
}

class ViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    var webView: WKWebView!
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func handleMessage(_ body: String) {
        if let data = body.data(using: .utf8) {
            do {
                if let message = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    handleJSONMessage(message)
                }
            } catch {
                // Handle JSON parsing exception
                print("Error parsing JSON: \(error)")
            }
        }
    }
    
    func handleJSONMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else {
            return
        }

        // callback message handling examples
        if type == "onClose" { 
            showAlert(title: type, message: "User clicked close button")
        } else if type == "onClickProduct" {
            handleOnClickProduct(message: message)
        }
    }

    func handleOnClickProduct(message: [String: Any]) {
        guard let payloadArray = message["payload"] as? [[String: Any]], !payloadArray.isEmpty else {
            return
        }

        let payload = payloadArray[0]
        
        guard let url = payload["url"] as? String, let productId = payload["id"] as? String else {
            return
        }

        let title = "User clicked product"
        let description = "id: \(productId)\nurl: \(url)"
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: title, message: description)
        }
    }

    // All the revieve-web-plugin events arrive here and can be used in the native app as you see fit
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Received a message from the revieve plugin:")
        print(message.body)
        if let body = message.body as? String {
            handleMessage(body)
        }
    }

    override func loadView() {
        // Generate the JS that calls the native app when events happen in revieve-web-plugin
        let js = """
                (function() {
                    window.parent = {
                        postMessage: function(data, target) {
                            if (target !== "\(Revieve.ORIGIN)" && target !== "\(Revieve.CDN_DOMAIN)") return;
                            if (data === undefined || data === "undefined") return;
                            var dataNormalized = typeof data === "object" ? JSON.stringify(data) : data.toSring();
                            if (window.webkit.messageHandlers.revieveMessageHandler) window.webkit.messageHandlers.revieveMessageHandler.postMessage(dataNormalized);
                        }
                    }
                    true;
                })()
            """

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController.add(self, name: "revieveMessageHandler")

        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webConfiguration.userContentController.addUserScript(script)
        webConfiguration.allowsInlineMediaPlayback = true
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self

        view = webView

        // Set up a demo PDP button
        if (Revieve.SHOW_PDP_BUTTON) {
            setupPDPButton()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: Revieve.FULL_URL!))
    }

    func setupPDPButton() {
        let pdpButton = UIButton(type: .system)
        pdpButton.addTarget(self, action: #selector(pdpButtonClicked), for: .touchUpInside)
        pdpButton.translatesAutoresizingMaskIntoConstraints = false
        pdpButton.setImage(UIImage(systemName: "mouth.fill"), for: .normal)
        pdpButton.tintColor = .red
        pdpButton.backgroundColor = .white // Set background color
        pdpButton.layer.cornerRadius = 8
        view.addSubview(pdpButton)

        let minHeight: CGFloat = 44
        let minWidth: CGFloat = 44
        let buttonSize = pdpButton.intrinsicContentSize
        let verticalPadding = max((minHeight - buttonSize.height) / 2, 0)
        let horizontalPadding = max((minWidth - buttonSize.width) / 2, 0)
        pdpButton.contentEdgeInsets = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)

        view.addSubview(pdpButton)

        let padding: CGFloat = 16

        NSLayoutConstraint.activate([
            pdpButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            pdpButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
        ])

    } 

    @objc func pdpButtonClicked() {
        let productId = "02762"
        let action = "{\"type\":\"tryonProduct\", \"payload\": {\"id\":\"\(productId)\"}}"
        webView.evaluateJavaScript("window.postMessage(\(action), '*')", completionHandler: nil)
    }
}
