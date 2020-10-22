//
//  ForemWebView.swift
//  ForemWebView-ios
//
//  Created by Fernando Valverde on 9/28/20.
//

import UIKit
import WebKit
import AVKit

public protocol ForemWebViewDelegate: class {
    func willStartNativeVideo(playerController: AVPlayerViewController)
}

public struct ForemUserData: Codable {
    enum CodingKeys: String, CodingKey {
        case userID = "id"
        case configBodyClass = "config_body_class"
    }
    public var userID: Int
    public var configBodyClass: String
}

open class ForemWebView: WKWebView {

    var foremWebViewDelegate: ForemWebViewDelegate?
    var videoPlayerLayer: AVPlayerLayer?
    open var baseHost: String?
    
    lazy var mediaManager: ForemMediaManager = {
        return ForemMediaManager(webView: self)
    }()
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupConfigurationIfInvertedColorsEnabled()
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }

    open func setup(navigationDelegate: WKNavigationDelegate, foremWebViewDelegate: ForemWebViewDelegate) {
        customUserAgent = "forem-native-ios"
        self.navigationDelegate = navigationDelegate
        self.foremWebViewDelegate = foremWebViewDelegate

        configuration.userContentController.add(self, name: "haptic")
        configuration.userContentController.add(self, name: "podcast")
        if AVPictureInPictureController.isPictureInPictureSupported() {
            configuration.userContentController.add(self, name: "video")
        }

        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        allowsBackForwardNavigationGestures = true
    }
    
    open func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
            if baseHost == nil {
                baseHost = url.host
            }
        }
    }
    
    open func isOAuthUrl(_ url: URL) -> Bool {
        return url.absoluteString.hasPrefix("https://github.com/login") || url.absoluteString.hasPrefix("https://api.twitter.com/oauth") ||
            url.absoluteString.hasPrefix("https://www.facebook.com/login.php") ||
            url.absoluteString.hasPrefix("https://www.facebook.com/v4.0/dialog/oauth")
    }

    open func fetchUserStatus(completion: @escaping (String?) -> Void) {
        let javascript = "document.getElementsByTagName('body')[0].getAttribute('data-user-status')"
        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            guard error == nil, let jsonString = result as? String else {
                print("Error getting user data: \(String(describing: error))")
                completion(nil)
                return
            }
            completion(jsonString)
        }
    }

    open func fetchUserData(completion: @escaping (ForemUserData?) -> Void) {
        let javascript = "document.getElementsByTagName('body')[0].getAttribute('data-user')"
        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            guard error == nil, let jsonString = result as? String else {
                print("Error getting user data: \(String(describing: error))")
                completion(nil)
                return
            }

            do {
                let user = try JSONDecoder().decode(ForemUserData.self, from: Data(jsonString.utf8))
                completion(user)
            } catch {
                print("Error info: \(error)")
                completion(nil)
            }
        }
    }

    open func sendBridgeMessage(type: String, message: [String: String]) {
        var jsonString = ""
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(message) {
            jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        }

        var javascript = ""
        if type == "podcast" {
            javascript = "document.getElementById('audiocontent').setAttribute('data-podcast', '\(jsonString)')"
        } else if type == "video" {
            javascript = "document.getElementById('video-player-source').setAttribute('data-message', '\(jsonString)')"
        }
        evaluateJavaScript(wrappedJS(javascript)) { _, error in
            if let error = error {
                print("Error sending Podcast message (\(message)): \(error.localizedDescription)")
            }
        }
    }

    open func shouldUseShellShadow(completion: @escaping (Bool) -> Void) {
        let javascript = "document.getElementById('page-content').getAttribute('data-current-page')"
        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            guard error == nil, let result = result as? String else {
                print("Error getting 'page-content' - 'data-current-page': \(String(describing: error))")
                completion(true)
                return
            }

            if result == "stories-show" {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func closePodcastUI() {
        let javascript = "document.getElementById('closebutt').click()"
        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            guard error == nil else {
                print("Error closing Podast: \(String(describing: error))")
                return
            }
        }
    }
    
    private func wrappedJS(_ javascript: String) -> String {
        return "try { \(javascript) } catch (err) { console.log(err) }"
    }
    
    open func setShellShadow(_ useShadow: Bool) {
        if useShadow {
            layer.shadowColor = UIColor.gray.cgColor
            layer.shadowOffset = CGSize(width: 0.0, height: 0.9)
            layer.shadowOpacity = 0.5
            layer.shadowRadius = 0.0
        } else {
            layer.shadowOpacity = 0.0
        }
    }

    private func setupConfigurationIfInvertedColorsEnabled() {
        guard let path = Bundle.main.path(forResource: "invertedImages", ofType: "css"),
            let cssString = try? String(contentsOfFile: path).components(separatedBy: .newlines).joined(),
            !UIAccessibility.isInvertColorsEnabled else {
            return
        }

        let source = """
            var style = document.createElement('style');
            style.innerHTML = '\(cssString)';
            document.head.appendChild(style);
            """

        let userScript = WKUserScript(source: source,
                                      injectionTime: .atDocumentEnd,
                                      forMainFrameOnly: true)

        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        configuration.userContentController = userContentController
        accessibilityIgnoresInvertColors = true
    }
}

