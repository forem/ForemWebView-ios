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

    private func handleImagePicker(_ message: [String: String]) {
        fetchCSRF { (res) in
            print("RES: \(res)")
            print("RES")
        }
        
        // TODO: Consider possible scenarios where the guard fails
        guard let elementId = message["id"] else { return }
        
        let picker = YPImagePicker()
        picker.didFinishPicking { [unowned picker] items, _ in
            if let photo = items.singlePhoto {
                print(photo.fromCamera) // Image source (camera or library)
                print(photo.image) // Final image selected by the user
                print(photo.originalImage) // original image selected by the user, unfiltered
                print(photo.modifiedImage) // Transformed image, can be nil
                print(photo.exifMeta) // Print exif meta data of original image.
//                print(photo.exifMeta["Orientation"])
                self.injectImageForUpload(elementId: elementId, image: photo.image)
            }
            picker.dismiss(animated: true, completion: nil)
        }

        if let delegateViewController = foremWebViewDelegate as? UIViewController {
            delegateViewController.present(picker, animated: true, completion: nil)
//            ps.showPreview(animate: true, sender: sender)
        }
    }

    private func injectImageForUpload(elementId: String, image: UIImage) {
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
            let uploadUrl = "https://\(domain)/image_uploads"
            image.imageResized(to: imageSize).uploadToForem(uploadUrl: uploadUrl, token: token) { (result) in
                if let result = result {
                    print("AWWWW YEAHHH: \(result)")
                } else {
                    print("AWWWW NNOOOAAAAHH")
                }
            }
        } else {
            print("ERROROROROOROR")
        }

//        guard let imageData = image.imageResized(to: imageSize).pngData() else { return }
//        let base64Data = "img-src data:image/png;base64, \(imageData.base64EncodedString())"
//        let javascript = """
//                            let element = document.getElementById('\(elementId)');
//                            element.value = '\(base64Data)';
//                            let changeEvent = new Event('change', { bubbles: true });
//                            element.dispatchEvent(changeEvent);
//                         """
//
//        evaluateJavaScript(wrappedJS(javascript)) { _, error in
//            guard error == nil else {
//                print("Error closing Podcast: \(String(describing: error))")
//                return
//            }
//        }
    }
}
