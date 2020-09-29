//
//  ForemWebView+WKScriptMessageHandler.swift
//  ForemWebView
//
//  Created by Fernando Valverde on 9/28/20.
//

import WebKit

extension ForemWebView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "podcast":
            self.mediaManager.handlePodcastMessage(message.body as? [String: String] ?? [:])
        case "video":
            mediaManager.handleVideoMessage(message.body as? [String: String] ?? [:])
        case "haptic":
            guard let hapticType = message.body as? String else { return }
            switch hapticType {
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
        default: ()
        }
    }
}
