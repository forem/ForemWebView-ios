import UIKit
import WebKit
import YPImagePicker

enum BridgeMessageType {
    case podcast, video
}

extension ForemWebView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        switch message.name {
        case "podcast":
            mediaManager.handlePodcastMessage(message.body as? [String: String] ?? [:])
        case "video":
            mediaManager.handleVideoMessage(message.body as? [String: String] ?? [:])
        case "body":
            updateUserData()
        case "imageUpload":
            handleImagePicker(message.body as? [String: String] ?? [:])
        case "haptic":
            guard let hapticType = message.body as? String else { return }
            handleHapticMessage(type: hapticType)
        default: ()
        }
    }

    // Helper function that will send Bridge messages into the DOM
    internal func sendBridgeMessage(type: BridgeMessageType, message: [String: String]) {
        var jsonString = ""
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(message) {
            jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        }

        var javascript = ""
        // Supported messages
        switch type {
        case .podcast:
            javascript = "document.getElementById('audiocontent').setAttribute('data-podcast', '\(jsonString)')"
        case .video:
            javascript = "document.getElementById('video-player-source').setAttribute('data-message', '\(jsonString)')"
        }

        guard !javascript.isEmpty else { return }
        evaluateJavaScript(wrappedJS(javascript)) { _, error in
            if let error = error {
                print("Error sending Podcast message (\(message)): \(error.localizedDescription)")
            }
        }
    }

    private func handleHapticMessage(type: String) {
        switch type {
        case "heavy":
            let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
            heavyImpact.impactOccurred()
        case "light":
            let lightImpact = UIImpactFeedbackGenerator(style: .light)
            lightImpact.impactOccurred()
        case "medium":
            let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
            mediumImpact.impactOccurred()
        default:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    // MARK: - Image Uploads

    func handleImagePicker(_ message: [String: String]) {
        // TODO: Consider possible scenarios where the guard fails
        guard let targetElementId = message["id"] else { return }

        let picker = YPImagePicker()
        picker.didFinishPicking { [unowned picker] items, _ in
            if let photo = items.singlePhoto {
                let message = ["action": "uploading"]
                self.injectImageMessage(message, targetElementId: targetElementId)
                self.uploadImage(elementId: targetElementId, image: photo.image)
            }
            picker.dismiss(animated: true, completion: nil)
        }

        if let delegateViewController = foremWebViewDelegate as? UIViewController {
            delegateViewController.present(picker, animated: true, completion: nil)
        }
    }

    func injectImageMessage(_ message: [String: String], targetElementId: String) {
        var jsonString = ""
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(message) {
            jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        }

        // React doesn't trigger `onChange` when updating the value of inputs
        // programmatically, so we are forced to dispatch the event manually
        let javascript = """
                            let element = document.getElementById('\(targetElementId)');
                            element.value = `\(jsonString)`;
                            let changeEvent = new Event('change', { bubbles: true });
                            element.dispatchEvent(changeEvent);
                         """
        evaluateJavaScript(wrappedJS(javascript)) { _, error in
            guard error == nil else {
                print(error.debugDescription)
                return
            }
        }
    }

    func uploadImage(elementId: String, image: UIImage) {
        // If the image has a large dimension make sure we resize
        var imageSize = image.size
        if image.size.width > 1000 {
            let ratio = 1000.0 / image.size.width
            imageSize = CGSize(width: ratio * imageSize.width, height: ratio * imageSize.height)
        } else if image.size.height > 1000 {
            let ratio = 1000.0 / image.size.height
            imageSize = CGSize(width: ratio * imageSize.width, height: ratio * imageSize.height)
        }

        if let token = csrfToken, let domain = self.foremInstance?.domain {
            // Support the simulator
            let requestProtocol = domain == "localhost" ? "http://" : "https://"
            let uploadUrl = "\(requestProtocol)\(domain)/image_uploads"

            image.imageResized(to: imageSize).uploadToForem(uploadUrl: uploadUrl, token: token) { (success, error) in
                if let result = success as String? {
                    var message = ["action": "success", "link": result]
                    if !result.contains(requestProtocol) {
                        message["link"] = "\(requestProtocol)\(domain)\(result)"
                    }
                    self.injectImageMessage(message, targetElementId: elementId)
                } else {
                    let message = ["action": "error", "error": error ?? "Unexpected error"]
                    self.injectImageMessage(message, targetElementId: elementId)
                }
            }
        } else {
            let message = ["action": "error", "message": "Unexpected error"]
            self.injectImageMessage(message, targetElementId: elementId)
        }
    }
}
