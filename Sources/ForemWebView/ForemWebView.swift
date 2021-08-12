#if os(iOS)

import UIKit
import WebKit
import AVKit

public protocol ForemWebViewDelegate: AnyObject {
    func willStartNativeVideo(playerController: AVPlayerViewController)
    func requestedExternalSite(url: URL)
    func requestedMailto(url: URL)
    func didStartNavigation()
    func didFinishNavigation()
    func didFailNavigation()
    func didLogin(userData: ForemUserData)
    func didLogout(userData: ForemUserData)
}

public enum ForemWebViewError: Error {
    case invalidInstance(String)
}

public enum ForemWebViewTheme {
    case base, night, minimal, pink, hacker
}

open class ForemWebView: WKWebView {

    var videoPlayerLayer: AVPlayerLayer?
    var cachedState: ForemWebViewCachedState?

    open weak var foremWebViewDelegate: ForemWebViewDelegate?
    open var foremInstance: ForemInstanceMetadata?
    open var csrfToken: String?
    open var userDeviceTokenConfirmed = false

    @objc open dynamic var userData: ForemUserData?
    var userDataTimer: Timer?

    lazy var mediaManager: ForemMediaManager = {
        return ForemMediaManager(webView: self)
    }()

    required public init?(coder: NSCoder) {
        let customConfig = ForemWebView.configuration()
        super.init(frame: UIScreen.main.bounds, configuration: customConfig)
        setupWebView()
    }

    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        let customConfig = ForemWebView.configuration(base: configuration)
        super.init(frame: frame, configuration: customConfig)
        setupWebView()
    }
    
    // Helper function that helps recreate a custom configuration required before instantiation (init methods)
    class func configuration(base configuration: WKWebViewConfiguration = WKWebViewConfiguration()) -> WKWebViewConfiguration {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let frameworkIdentifier = "ForemWebView/\(version ?? "0.0")"
        configuration.applicationNameForUserAgent = frameworkIdentifier

        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        return configuration
    }

    func setupWebView() {
        configuration.userContentController.add(self, name: "haptic")
        configuration.userContentController.add(self, name: "body")
        configuration.userContentController.add(self, name: "podcast")
        configuration.userContentController.add(self, name: "imageUpload")
        if AVPictureInPictureController.isPictureInPictureSupported() {
            configuration.userContentController.add(self, name: "video")
        }
        allowsBackForwardNavigationGestures = true
        navigationDelegate = self
        uiDelegate = self
    }

    open func clearReferences() {
        configuration.userContentController.removeAllUserScripts()
        configuration.userContentController.removeAllScriptMessageHandlers()
        configuration.userContentController.removeAllContentRuleLists()
        navigationDelegate = nil
        uiDelegate = nil
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
    
    // Helper function that performs a load on the webView. It's the recommended interface to use
    // if a cached state has been stored. It will display the cached snapshot until the webview has
    // had time to load the custom URL of the cached state.
    open func load(_ cachedState: ForemWebViewCachedState) {
        if let url = URL(string: cachedState.customURL) {
            let request = URLRequest(url: url)
            load(request)
        }
        
        self.cachedState = cachedState
        addSubview(cachedState.snapshot)
        cachedState.snapshot.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
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
        let fbRegex =  #"https://(www|m)?\.facebook\.com/(v\d+.\d+/dialog/oauth|login.php)"#

        return gitHubAuth || twitterAuth || url.absoluteString.range(of: fbRegex, options: .regularExpression) != nil
    }

    // Async callback will return the `ForemUserData` struct, which encapsulates some information
    // regarding the currently logged in user. It will return `nil` if this data isn't available
    open func fetchUserData(completion: @escaping (ForemUserData?) -> Void) {
        var javascript = ""
        if let fileURL = Bundle.module.url(forResource: "fetchUserData", withExtension: "js"),
           let fileContents = try? String(contentsOf: fileURL.absoluteURL) {
            javascript = fileContents
        }

        guard !javascript.isEmpty else { return }
        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            guard let jsonString = result as? String else {
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

    // Function that fetches the CSRF Token required for direct interaction with the Forem servers
    func fetchCSRF(completion: @escaping (String?) -> Void) {
        evaluateJavaScript(wrappedJS("window.csrfToken")) { result, error in
            if let error = error {
                print("Unable to fetch CSRF Token: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(result as? String ?? nil)
            }
        }
    }

    // Function that will update the observable userData variable by reusing `fetchUserData`
    func updateUserData() {
        self.fetchUserData { (userData) in

            // Whenever changes in the DOM trigger a `updateUserData` call is when we `fetchUserData`.
            // Then we update `self.userData` only if something has changed. This allows the consumers
            // of the framework to observe `self.userData` and expect changes when something has changed
            if self.userData != userData {

                // If changes occurred we want to update the CSRF token as well
                self.fetchCSRF { (token) in
                    self.csrfToken = token

                    if let userData = userData {
                        // Notify the delegate of newly logged in user and save it to `self.userData`
                        if userData.userID != self.userData?.userID {
                            self.foremWebViewDelegate?.didLogin(userData: userData)
                        }
                        self.userData = userData
                    } else {
                        // Notify the delegate of the recently logged out user and clear `self.userData`
                        if let prevUserData = self.userData {
                            self.foremWebViewDelegate?.didLogout(userData: prevUserData)
                        }
                        self.userData = nil
                    }
                }
            }
        }
    }

    // Function that will ensure the ForemWebView is initialized using a valid Forem Instance. It will
    // update `foremInstance` variable which will help provide metadata about the initialized ForemWebView.
    // It will also call `failIfInvalidInstanceError` if unable to populate the metadata on the first load.
    func ensureForemInstance() {
        guard foremInstance == nil else { return }

        var javascript = ""
        if let fileURL = Bundle.module.url(forResource: "fetchForemInstanceMetadata", withExtension: "js"),
           let fileContents = try? String(contentsOf: fileURL.absoluteURL) {
            javascript = fileContents
        }

        guard !javascript.isEmpty else { return }
        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            guard let jsonString = result as? String else {
                print("Unable to fetch Forem Instance Metadata: \(String(describing: error))")
                return
            }

            do {
                self.foremInstance = try JSONDecoder().decode(ForemInstanceMetadata.self, from: Data(jsonString.utf8))
            } catch {
                print("Error parsing Forem Instance Metadata: \(error)")
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
    func wrappedJS(_ javascript: String) -> String {
        // TODO: Consider using Honeybadger/Datadog/Ahoy/etc for these error handlers (JS side)
        return "try { \(javascript) } catch (err) { console.log(err) }"
    }
}

#endif
