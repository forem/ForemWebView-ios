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

    private func handleImagePicker(_ message: [String: String]) {
        let picker = YPImagePicker()
        picker.didFinishPicking { [unowned picker] items, _ in
            if let photo = items.singlePhoto {
                print(photo.fromCamera) // Image source (camera or library)
                print(photo.image) // Final image selected by the user
                print(photo.originalImage) // original image selected by the user, unfiltered
                print(photo.modifiedImage) // Transformed image, can be nil
                print(photo.exifMeta) // Print exif meta data of original image.
            }
            picker.dismiss(animated: true, completion: nil)
        }

        if let delegateViewController = foremWebViewDelegate as? UIViewController {
            delegateViewController.present(picker, animated: true, completion: nil)
//            ps.showPreview(animate: true, sender: sender)
        }
    }
}
