#if os(iOS)

import UIKit
import WebKit
import AlamofireImage
import YPImagePicker

enum BridgeMessageType: String {
    case podcast = "podcast"
    case video = "video"
    case imageUpload = "imageUpload"
    case coverImageUpload = "coverUpload"
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
            handleImagePicker(message.body as? [String: String] ?? [:], type: .imageUpload)
        case "coverUpload":
            handleImagePicker(message.body as? [String: String] ?? [:], type: .coverImageUpload)
        case "haptic":
            guard let hapticType = message.body as? String else { return }
            handleHapticMessage(type: hapticType)
        default: ()
        }
    }

    // Helper function that will send Bridge messages into the DOM
    internal func sendBridgeMessage(_ message: [String: String], type: BridgeMessageType) {
        // Add the namespace to the payload
        var payload = message
        payload["namespace"] = type.rawValue

        var jsonString = ""
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(message) {
            jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        }

        let javascript = "window.ForemMobile?.injectJSMessage('\(jsonString)')"
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
    func handleImagePicker(_ message: [String: String], type: BridgeMessageType) {
        let picker = imagePicker(message["ratio"])
        picker.didFinishPicking { [unowned picker] items, _ in
            // Callback for when the native image picker process is completed by the user
            if let photo = items.singlePhoto {
                // Image selected now start uploading process
                let message = ["action": "uploading"]
                self.sendBridgeMessage(message, type: type)
                self.uploadImage(photo.image, type: type)
            }
            picker.dismiss(animated: true, completion: nil)
        }

        // Use 'foremWebViewDelegate' as the 'pivot' ViewController to present the native picker
        if let delegateViewController = foremWebViewDelegate as? UIViewController {
            delegateViewController.present(picker, animated: true, completion: nil)
        }
    }

    // Function that will upload a UIImage directly to the Forem instance
    func uploadImage(_ image: UIImage, type: BridgeMessageType) {
        guard let token = csrfToken, let domain = self.foremInstance?.domain else {
            let message = ["action": "error", "message": "Unexpected error"]
            self.sendBridgeMessage(message, type: type)
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
                self.sendBridgeMessage(message, type: type)
            } else {
                let message = ["action": "error", "error": error ?? "Unexpected error"]
                self.sendBridgeMessage(message, type: type)
            }
        }
    }
}

#endif
