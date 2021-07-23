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

// Load the revieve-web-plugin from Revieve's production CDN:
let REVIEVE_CDN_DOMAIN = "https://d38knilzwtuys1.cloudfront.net"
// Origin set to *
let REVIEVE_ORIGIN = "*"
// Select which Revieve API environment to use. Can be test or prod
let REVIEVE_ENV = "test"
// Partner ID
let REVIEVE_PARTNER_ID = "kToSMAjsNx"

// Construct the full URL
let REVIEVE_FULL_URL = URL(string:"\(REVIEVE_CDN_DOMAIN)/revieve-plugin-v4/app.html?partnerId=\(REVIEVE_PARTNER_ID)&env=\(REVIEVE_ENV)&crossOrigin=1&origin=\(REVIEVE_ORIGIN)")


class ViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    var webView: WKWebView!
    
    // All the revieve-web-plugin events arrive here and can be used in the native app as you see fit
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Received a message from the revieve plugin:")
        print(message.body)
    }

    override func loadView() {
        // Generate the JS that calls the native app when events happen in revieve-web-plugin
        let js = """
                (function() {
                    window.parent = {
                        postMessage: function(data, target) {
                            if (target !== "\(REVIEVE_ORIGIN)" && target !== "\(REVIEVE_CDN_DOMAIN)") return;
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: REVIEVE_FULL_URL!))
    }

}
