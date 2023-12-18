# Revieve WKWebView Integration Sample

This repository contains a sample iOS application demonstrating how to integrate our plugin solution within a native app using WKWebView. The primary goal of this sample project is to provide developers with a clear and concise guide for integrating our plugin into their native applications.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Integration Steps](#integration-steps)
3. [Communication with plugin](#communication-with-plugin)

## Getting Started

Before you begin, ensure you have the following prerequisites:

- Xcode installed on your development machine.
- An iOS device or simulator.
- A partnerId provided by Revieve.

Clone the repository and open the project in Xcode:

```bash
git clone https://github.com/revieve/revieve-plugin-wkwebview-sample.git
cd revieve-plugin-wkwebview-sample
open revieve-plugin-wkwebview-sample.xcodeproj
```

## Integration Steps

Follow these step-by-step instructions to integrate the plugin solution into your iOS application using WKWebView:

1. **Configure partnerId and environment:**

In your `ViewController.swift` file, setup the configuration variables as instructed by our implementation team:

```swift
  // Select which Revieve API environment to use. Can be test or prod
static let ENV = "test"
// your partner Id provided by Revieve
static let PARTNER_ID = "GHru81v4aU"
```

2. **Configure the WKWebView:**

Set up a `WKWebViewConfiguration` instance, configure it with necessary settings, and create a `WKWebView` instance using the configuration:

```swift
let webConfiguration = WKWebViewConfiguration()
webConfiguration.allowsInlineMediaPlayback = true
webView = WKWebView(frame: .zero, configuration: webConfiguration)
webView.uiDelegate = self
```

3. **Inject JavaScript:**

Add a JavaScript code snippet to your `WKWebViewConfiguration`` instance that defines the configuration (including callbacks) for the plugin solution:

```swift
let jsConfig = """
window.revieveConfig = {
    partner_id: '\(Revieve.PARTNER_ID)',
    locale: '\(Revieve.LOCALE)',
    env: '\(Revieve.ENV)',
    disableLauncherButton: true,
    onClickProduct: function(product) {
        postMessageToCallbackHandler('onClickProduct', [ product ]);
    },
    // you can implement rest of callbacks here as described in Revieve documentation
};
"""
```

4. **Handle callbacks:**

As seen in the previous step, the plugin solution will send callbacks to the `postMessageToCallbackHandler` function. Implement this function in your view controller to handle incoming callbacks and add it to the webview configuration:

```swift
class ViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
  var webView: WKWebView!

  override func loadView() {
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.userContentController.add(self, name: "revieveMessageHandler")
    // ...
  }

  webConfiguration.userContentController.add(self, name: "revieveMessageHandler")
  //...
  // All passed callback events arrive here and can be used in the native app as you see fit
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      if message.name == "revieveMessageHandler", let messageBody = message.body as? String {
          print("Received message from Revieve: \(messageBody)")
          handleMessage(messageBody);
      }
  }
}
```

5. **Load the plugin:**

Load the included HTML template into the webview using the `loadHTMLString` method.

```swift
func loadRevieveHTML() {
  if let htmlPath = Bundle.main.path(forResource: "revieve", ofType: "html") {
    do {
      let htmlContent = try String(contentsOfFile: htmlPath, encoding: .utf8)
      webView.loadHTMLString(htmlContent, baseURL: URL(string:"https://d38knilzwtuys1.cloudfront.net/revieve-plugin-v4/app.html"))
    } catch {
      print("Error loading HTML file: \(error)")
    }
  }
}
```

## Communication with plugin

The sample project provides basic integration with the plugin solution. Customize the response to plugin callbacks by modifying the source code as needed.

Refer to the plugin solution's basic and advanced documentation for details on available callbacks and data options.

The `postMessage`` API enables seamless communication between the plugin solution and your native application. This section guides you through setting up and handling `postMessage`` communication in the WKWebView integration sample.

### Handling PostMessage Events

Implement the `userContentController(_:didReceive:)` method in your view controller to handle incoming `postMessage` events:

```swift
class ViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    // All passed callback events arrive here and can be used in the native app as you see fit
  }
}
```

Inside the `userContentController(_:didReceive:)` method, you can parse the JSON message body and perform actions based on the received events. For example, you may want to display an alert when a specific event is triggered:

```swift
func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
  if message.name == "revieveMessageHandler", let messageBody = message.body as? String {
    print("Received message from Revieve: \(messageBody)")
    handleMessage(messageBody);
  }
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
```

Refer to the plugin solution's documentation for a comprehensive list of available events and their payloads.

### Sending API Commands

In some cases, like PDP try-on integration, you may want to send commands from your native app to the Revive API. This section demonstrates how to call a JavaScript function in the plugin solution from your native app.

1. **Create a function to send the command:**

For example, let's say you want to send a `tryonProduct` command with a specific product ID when a button is clicked.

```swift
@objc func pdpButtonClicked() {
  let productId = "02750"
  print("call addTryOnProduct with id \(productId)")
  webView.evaluateJavaScript("window.Revieve.API.liveAR.addTryOnProduct('\(productId)');")
}
```

In the example above, a javascript Revieve API function is called directly with the product ID as a parameter.

2. **Add a button to trigger the command:**

Add a UIButton to your app's user interface that triggers the `pdpButtonClicked` function when clicked. Don't forget to add the following line in the button setup to connect the button to the `pdpButtonClicked` function:

```swift
  pdpButton.addTarget(self, action: #selector(pdpButtonClicked), for: .touchUpInside)
```

In the source code you can set Revieve.SHOW_PDP_BUTTON to `true` to see a demo implementation of the PDP button communication.

By following these steps, you can enable two-ways communication between your app and the plugin.

### Legacy integration without loader script

You can find our legacy documentation for integrating the plugin solution without the loader script [here](https://github.com/revieve/revieve-plugin-wkwebview-sample/tree/legacy)