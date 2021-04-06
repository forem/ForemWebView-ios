#if os(iOS)

import UIKit
import WebKit
import AlamofireImage
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

    // Builds, configures and returns an YPImagePicker
    func imagePicker(_ ratio: String?) -> YPImagePicker {
        var config = YPImagePickerConfiguration()
        config.shouldSaveNewPicturesToAlbum = false
        config.startOnScreen = YPPickerScreen.library
        config.library.onlySquare = false
        config.library.isSquareByDefault = false
        if let ratio = ratio, let rectangleRatio = Double(ratio) {
            config.showsCrop = .rectangle(ratio: rectangleRatio)
        }
        config.library.mediaType = YPlibraryMediaType.photo
        return YPImagePicker(configuration: config)
    }

    // Whenever a request to select an image is triggered via WKScriptMessageHandler
    func handleImagePicker(_ message: [String: String]) {
        guard let targetElementId = message["id"] else { return }

        let picker = imagePicker(message["ratio"])
        picker.didFinishPicking { [unowned picker] items, _ in
            // Callback for when the native image picker process is completed by the user
            if let photo = items.singlePhoto {
                // Image selected now start uploading process
                let message = ["action": "uploading"]
                self.injectImageMessage(message, targetElementId: targetElementId)
                self.uploadImage(elementId: targetElementId, image: photo.image)
            }
            picker.dismiss(animated: true, completion: nil)
        }

        // Use 'foremWebViewDelegate' as the 'pivot' ViewController to present the native picker
        if let delegateViewController = foremWebViewDelegate as? UIViewController {
            delegateViewController.present(picker, animated: true, completion: nil)
        }
    }

    // This function will inject a message back into the image selector that triggered the request
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

    // Function that will upload a UIImage directly to the Forem instance
    func uploadImage(elementId: String, image: UIImage) {
        guard let token = csrfToken, let domain = self.foremInstance?.domain else {
            let message = ["action": "error", "message": "Unexpected error"]
            self.injectImageMessage(message, targetElementId: elementId)
            return
        }

        // Support the simulator
        let requestProtocol = domain == "localhost:3000" ? "http://" : "https://"
        let targetUrl = "\(requestProtocol)\(domain)/image_uploads"

        let optimizedImage = image.af.imageScaled(to: image.foremLimitedSize())
        optimizedImage.uploadTo(url: targetUrl, token: token) { (link, error) in
            if let link = link as String? {
                var message = ["action": "success", "link": link]
                if !link.contains(requestProtocol) {
                    message["link"] = "\(requestProtocol)\(domain)\(link)"
                }
                self.injectImageMessage(message, targetElementId: elementId)
            } else {
                let message = ["action": "error", "error": error ?? "Unexpected error"]
                self.injectImageMessage(message, targetElementId: elementId)
            }
        }
    }
}

#endif
