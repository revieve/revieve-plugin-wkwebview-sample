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

    static let LOCALE = "en"
    // Select which Revieve API environment to use. Can be test or prod
    static let ENV = "test"
    // static let PARTNER_ID = "9KpsLizwYK" // skincare demo
    static let PARTNER_ID = "GHru81v4aU" // vto makeup demo
    // PDP VTO trigger example
    static let SHOW_PDP_BUTTON = true
    // Construct the full URL
    static let LOADER_URL = URL(string: "\(CDN_DOMAIN)/revieve-plugin-v4/revieve-plugin-loader.js")
}

class ViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    var webView: WKWebView!
    
    override func loadView() {

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController.add(self, name: "revieveMessageHandler")
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
        let htmlString = """
            <html>
            <head>
                <title>Revieve Advisor</title>
                <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, minimal-ui" />
                <script type="text/javascript">
                function postMessageToCallbackHandler(type, payload) {
                    const message = { type, payload };
                    const serializedMessage = JSON.stringify(message);
                    window.webkit.messageHandlers.revieveMessageHandler.postMessage(serializedMessage);
                }
        
                var revieveConfig = {
                    partner_id: '\(Revieve.PARTNER_ID)',
                    locale: '\(Revieve.LOCALE)',
                    env: '\(Revieve.ENV)',
                    disableLauncherButton: true,
                    onClickProduct: function(product) {
                        postMessageToCallbackHandler('onClickProduct', [ product ]);
                    },
                    // you can implement rest of callbacks here as described in Revieve documentation
                };

                (function() {
                    var rv = document.createElement('script');
                    rv.src = '\(Revieve.CDN_DOMAIN)/revieve-plugin-v4/revieve-plugin-loader.js';
                    rv.charset = 'utf-8';
                    rv.type = 'text/javascript';
                    rv.async = 'true';
                    rv.onload = rv.onreadystatechange = function() {
                    var rs = this.readyState;
                    if (rs && rs != 'complete' && rs != 'loaded') return;
                    Revieve.Init(revieveConfig, function() {
                        // Comment out the below line if you want to open the modal
                        // manually when user clicks a certain button or navigates
                        // to certain page.
                        Revieve.API.show();
                    });
                    };
                    var s = document.getElementsByTagName('script')[0];
                    s.parentNode.insertBefore(rv, s);
                })();
                </script>
            </head>
            <body></body>
            </html>
        """
        webView.loadHTMLString(htmlString, baseURL: URL(string: "\(Revieve.CDN_DOMAIN)/revieve-plugin-v4/app.html"))
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

    // All passed callback events arrive here and can be used in the native app as you see fit
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "revieveMessageHandler", let messageBody = message.body as? String {
            print("Received message from Revieve: \(messageBody)")
            handleMessage(messageBody);
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
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
        let productId = "02750"
        print("call addTryOnProduct with id \(productId)")
        webView.evaluateJavaScript("window.Revieve.API.liveAR.addTryOnProduct('\(productId)');")
    }
    
    // Grants permission for media capture within the WebView for iOS 15 and above.
    // This avoids duplicate permission prompts, providing a smoother user experience.
    // TODO: Consider refining permission grants based on the security origin or other criteria.
    @available(iOS 15, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
}
