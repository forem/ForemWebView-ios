import WebKit

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
        case "haptic":
            guard let hapticType = message.body as? String else { return }
            handleHapticMessage(type: hapticType)
        default: ()
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
}
