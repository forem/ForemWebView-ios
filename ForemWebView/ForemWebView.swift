import UIKit
import WebKit
import AVKit

public protocol ForemWebViewDelegate: class {
    func willStartNativeVideo(playerController: AVPlayerViewController)
}

open class ForemWebView: WKWebView {

    var videoPlayerLayer: AVPlayerLayer?
    
    open var foremWebViewDelegate: ForemWebViewDelegate?
    open var baseHost: String?
    
    lazy var mediaManager: ForemMediaManager = {
        return ForemMediaManager(webView: self)
    }()
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        setupWebView()
    }

    // MARK: - Interface functions (open)
    
    open func setupWebView() {
        // This approach maintains a UserAgent format that most servers & third party services will see us
        // as non-malicious. Example: reCaptcha may take into account a "familiarly formatted" as more
        // trustworthy compared to bots thay may use more plain strings like "Forem"/"DEV"/etc
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent
        evaluateJavaScript("navigator.userAgent") { (result, error) in
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let frameworkIdentifier = "ForemWebView/\(version ?? "0.0")"
            if let result = result {
                self.customUserAgent = "\(result) \(frameworkIdentifier)"
            } else {
                print("Error: \(String(describing: error?.localizedDescription))")
                print("Unable to extend the base UserAgent. Will default to '\(frameworkIdentifier)'")
                self.customUserAgent = frameworkIdentifier
            }
        }

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
            
            // Set the baseHost on the first `load`
            if baseHost == nil {
                baseHost = url.host
            }
        }
    }
    
    open func isOAuthUrl(_ url: URL) -> Bool {
        // Takes into account GitHub OAuth paths including 2FA + error pages
        let gitHubAuth = url.absoluteString.hasPrefix("https://github.com/login") ||
                         url.absoluteString.hasPrefix("https://github.com/session")
        
        // Takes into account Twitter OAuth paths including error pages
        let twitterAuth = url.absoluteString.hasPrefix("https://api.twitter.com/oauth") ||
                          url.absoluteString.hasPrefix("https://twitter.com/login/error")
        
        // Regex that into account Facebook OAuth based on their API versions
        // Example: "https://www.facebook.com/v4.0/dialog/oauth"
        let fbRegex =  #"https://www\.facebook\.com/v\d+.\d+/dialog/oauth"#
        
        return gitHubAuth || twitterAuth || url.absoluteString.range(of: fbRegex, options: .regularExpression) != nil
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
        // Supported messages
        if type == "podcast" {
            javascript = "document.getElementById('audiocontent').setAttribute('data-podcast', '\(jsonString)')"
        } else if type == "video" {
            javascript = "document.getElementById('video-player-source').setAttribute('data-message', '\(jsonString)')"
        }
        
        guard javascript.count > 0 else { return }
        evaluateJavaScript(wrappedJS(javascript)) { _, error in
            if let error = error {
                print("Error sending Podcast message (\(message)): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Non-open functions
    
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
}

