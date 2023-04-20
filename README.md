# Revieve WKWebView Integration Sample

This repository contains a sample iOS application that demonstrates how to integrate our plugin solution within a native app using WKWebView. The primary goal of this sample project is to provide developers with a clear and concise guide for integrating our plugin with their native applications.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Integration Steps](#integration-steps)
3. [Communication with plugin](#communication-with-plugin)

## Getting Started

Before you begin, make sure you have the following prerequisites:

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

Follow these step-by-step instructions to integrate the plugin solution within your iOS application using WKWebView:

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

Add a JavaScript code snippet to your `WKWebViewConfiguration` instance that defines a custom `postMessage` function. This function will forward the received messages to your native app:

```swift
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
```

4. **Handle JavaScript messages:**

Conform your view controller to the `WKScriptMessageHandler` protocol and implement the `userContentController(_:didReceive:)` method to handle messages from the plugin:

```swift
extension ViewController: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    // Handle JavaScript messages here
  }
}
```

5. **Load the plugin:**

Create a `URLRequest` using the plugin solution's CDN URL and partner ID, and load it into the WKWebView instance:

```swift
  let request = URLRequest(url: pluginURL)
  webView.load(request)
```

6. **Add the WKWebView to your view hierarchy:**

Add the `WKWebView` instance to your view controller's view hierarchy:

```swift
  view.addSubview(webView)
```

## Communication with plugin

The sample project provides a basic integration with the plugin solution. You should customize custom behavior in response to plugin events by modifying the source code as needed.

Refer to the plugin solution's basic and advanced documentation for details on available callbacks and data options.

The `postMessage` API enables seamless communication between the plugin solution and your native application. This section will guide you through the process of setting up and handling `postMessage` communication in the WKWebView integration sample.

### Handling PostMessage Events

Implement the `userContentController(_:didReceive:)` method in your view controller to handle incoming `postMessage` events:

```swift
extension ViewController: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    // Handle JavaScript messages here
  }
}
```

Inside the `userContentController(_:didReceive:)` method, you can parse the JSON message body and perform actions based on the received events. For example, you may want to display an alert when a specific event is triggered:

```swift
func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
  if let body = message.body as? String {
    handleMessage(body)
  }
}

func handleMessage(_ body: String) {
  // Parse and handle the message here
  // ...
  if type == "someEventType" {
    showAlert(title: "Event triggered", message: "The 'someEventType' event has been triggered")
  }
}
```

Refer to the plugin solution's documentation for a comprehensive list of available events and their payloads.

### Sending PostMessage Commands

In some cases like PDP try-on integration you may want to send commands from your native app to the  plugin. This section will demonstrate how to send a command to the plugin using `postMessage` communication.

1. **Create a function to send the command:**

For example, let's say you want to send a `tryonProduct` command with a specific product ID when a button is clicked.

```swift
@objc func pdpButtonClicked() {
  let productId = "02762"
  let action = "{\"type\":\"tryonProduct\", \"payload\": {\"id\":\"\(productId)\"}}"
  webView.evaluateJavaScript("window.postMessage(\(action), '*')", completionHandler: nil)
}
```

In the example above, a JSON object is created with the appropriate `type` and `payload`. This JSON object is then sent to the WebView plugin using the `evaluateJavaScript` method.

2. **Add a button to trigger the command:**

Add a UIButton to your app's user interface that triggers the `pdpButtonClicked` function when clicked. Don't forget to add the following line in the button setup to connect the button to the `pdpButtonClicked` function:

```swift
  pdpButton.addTarget(self, action: #selector(pdpButtonClicked), for: .touchUpInside)
```

In the source code you can set Revieve.SHOW_PDP_BUTTON to `true` to see a demo implementation of the PDP button communication.

By following these steps, you can enable two-ways communication between your app and the plugin.