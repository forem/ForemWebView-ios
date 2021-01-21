#if os(iOS)

import UIKit
import WebKit
import AVKit

public protocol ForemWebViewDelegate: class {
    func willStartNativeVideo(playerController: AVPlayerViewController)
    func requestedExternalSite(url: URL)
    func requestedMailto(url: URL)
    func didStartNavigation()
    func didFinishNavigation()
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

    open weak var foremWebViewDelegate: ForemWebViewDelegate?
    open var foremInstance: ForemInstanceMetadata?
    open var csrfToken: String?
    open var userDeviceTokenConfirmed = false

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
        configuration.userContentController.add(self, name: "imageUpload")
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
        let fbRegex =  #"https://(www|m)?\.facebook\.com/(v\d+.\d+/dialog/oauth|login.php)"#

        return gitHubAuth || twitterAuth || url.absoluteString.range(of: fbRegex, options: .regularExpression) != nil
    }
    
    // MARK: - Non-open functions

    // Async callback will return the `ForemUserData` struct, which encapsulates some information
    // regarding the currently logged in user. It will return `nil` if this data isn't available
    func fetchUserData(completion: @escaping (ForemUserData?) -> Void) {
        var javascript = ""
        if let fileURL = Bundle.module.url(forResource: "fetchUserData", withExtension: "js"),
           let fileContents = try? String(contentsOf: fileURL.absoluteURL) {
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
            // This fetch will be executed whenever changes in the DOM trigger a `updateUserData` so we
            // dont override `self.userData` on every call, only when it changes. This allows the
            // consumers of the framework to tap into observing `self.userData` and expect changes when the
            // data has actually changed (nil -> 'something' means user logged-in, the opposite for logged-out)
            if self.userData != userData {
                self.fetchCSRF { (token) in
                    self.csrfToken = token
                    
                    if let userData = userData {
                        // Assign newly logged in userData and notify delegate
                        self.userData = userData
                        self.foremWebViewDelegate?.didLogin(userData: userData)
                    } else {
                        // Clear userData and pass in logged out userData. Done this way in case
                        // the consumer will check the current userData that is now logged out.
                        let tempUserData = self.userData
                        self.userData = nil
                        if let loggedOutUserData = tempUserData {
                            self.foremWebViewDelegate?.didLogout(userData: loggedOutUserData)
                        }
                    }
                }
            }
        }
    }

    // Function that will ensure the `body` element in the DOM has a mutation observer that will relay
    // attribute updates via a WebKit messageHandler (named `body`). See contents of `bodyMutationObserver.js`
    func ensureMutationObserver() {
        var javascript = ""
        if let fileURL = Bundle.module.url(forResource: "bodyMutationObserver", withExtension: "js"),
           let fileContents = try? String(contentsOf: fileURL.absoluteURL) {
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
