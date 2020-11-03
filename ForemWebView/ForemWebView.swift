import UIKit
import WebKit
import AVKit

public protocol ForemWebViewDelegate: class {
    func willStartNativeVideo(playerController: AVPlayerViewController)
    func requestedExternalSite(url: URL)
    func requestedMailto(url: URL)
    func didStartNavigation()
    func didFinishNavigation()
}

public enum ForemWebViewError: Error {
    case invalidInstance(String)
}

open class ForemWebView: WKWebView {

    var videoPlayerLayer: AVPlayerLayer?

    open weak var foremWebViewDelegate: ForemWebViewDelegate?
    open var foremInstance: ForemInstanceMetadata?

    @objc open dynamic var userData: ForemUserData?

    lazy var mediaManager: ForemMediaManager = {
        return ForemMediaManager(webView: self)
    }()

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }

    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        setupWebView()
    }

    func setupWebView() {
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
        configuration.userContentController.add(self, name: "body")
        configuration.userContentController.add(self, name: "podcast")
        if AVPictureInPictureController.isPictureInPictureSupported() {
            configuration.userContentController.add(self, name: "video")
        }

        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        allowsBackForwardNavigationGestures = true
        navigationDelegate = self
    }

    // MARK: - Interface functions (open)

    // Helper function that performs a load on the webView. It's the recommended interface to use
    // since it will keep track of the `baseHost` variable.
    open func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
        }
    }

    // Returns `true` if the url provided is considered of the supported 3rd party redirect URLs
    // in a OAuth protocol. Returns `false` otherwise.
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

    // Async callback will return the `ForemUserData` struct, which encapsulates some information
    // regarding the currently logged in user. It will return `nil` if this data isn't available
    open func fetchUserData(completion: @escaping (ForemUserData?) -> Void) {
        var javascript = ""
        if let filePath = Bundle(for: type(of: self)).path(forResource: "fetchUserData", ofType: "js"),
           let fileContents = try? String(contentsOfFile: filePath) {
            javascript = fileContents
        }

        guard !javascript.isEmpty else { return }
        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            guard let jsonString = result as? String else {
                print("No user data available: \(error?.localizedDescription ?? "Logged-out")")
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

    // MARK: - Non-open functions

    // Function that will update the observable userData variable by reusing `fetchUserData`
    func updateUserData() {
        self.fetchUserData { (userData) in
            if self.userData != userData {
                self.userData = userData
            }
        }
    }

    // Function that will ensure the `body` element in the DOM has a mutation observer that will relay
    // attribute updates via a WebKit messageHandler (named `body`). See contents of `bodyMutationObserver.js`
    func ensureMutationObserver() {
        var javascript = ""
        if let filePath = Bundle(for: type(of: self)).path(forResource: "bodyMutationObserver", ofType: "js"),
           let fileContents = try? String(contentsOfFile: filePath) {
            javascript = fileContents
        }

        guard !javascript.isEmpty else { return }
        evaluateJavaScript(wrappedJS(javascript)) { _, error in
            if let error = error {
                print("Unable to ensure body mutation observer: \(error.localizedDescription)")
                self.updateUserData()
            }
        }
    }

    // Function that will ensure the ForemWebView is initialized using a valid Forem Instance. It will
    // update `foremInstance` variable which will help provide metadata about the initialized ForemWebView.
    // It will also call `failIfInvalidInstanceError` if unable to populate the metadata on the first load.
    // swiftlint:disable force_try
    func ensureForemInstance() {
        guard foremInstance == nil else { return }

        var javascript = ""
        if let filePath = Bundle(for: type(of: self)).path(forResource: "fetchForemInstanceMetadata", ofType: "js"),
           let fileContents = try? String(contentsOfFile: filePath) {
            javascript = fileContents
        }

        guard !javascript.isEmpty else { return }
        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            guard let jsonString = result as? String else {
                print("Unable to fetch Forem Instance Metadata: \(String(describing: error))")
                try! self.failIfInvalidInstanceError()
                return
            }

            do {
                self.foremInstance = try JSONDecoder().decode(ForemInstanceMetadata.self, from: Data(jsonString.utf8))
            } catch {
                print("Error parsing Forem Instance Metadata: \(error)")
            }

            try! self.failIfInvalidInstanceError()
        }
    }
    // swiftlint:enable force_try

    // Helper function that will throw an error when the ForemWebView is initialized with a URL
    // that does not represent a valid Forem Instance.
    func failIfInvalidInstanceError() throws {
        if self.foremInstance == nil {
            throw ForemWebViewError.invalidInstance("Only Forem Instances are supported for this WebView")
        }
    }

    // Helper function that will send Bridge messages into the DOM
    func sendBridgeMessage(type: String, message: [String: String]) {
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

        guard !javascript.isEmpty else { return }
        evaluateJavaScript(wrappedJS(javascript)) { _, error in
            if let error = error {
                print("Error sending Podcast message (\(message)): \(error.localizedDescription)")
            }
        }
    }

    // Helper function to close the Podcast Player UI in the DOM
    func closePodcastUI() {
        let javascript = "document.getElementById('closebutt').click()"
        evaluateJavaScript(wrappedJS(javascript)) { _, error in
            guard error == nil else {
                print("Error closing Podcast: \(String(describing: error))")
                return
            }
        }
    }

    // Helper function to wrap JS errors in a way we don't pollute the JS Context with Mobile specific errors
    private func wrappedJS(_ javascript: String) -> String {
        // TODO: Consider using Honeybadger/Datadog/Ahoy/etc for these error handlers (JS side)
        return "try { \(javascript) } catch (err) { console.log(err) }"
    }
}
