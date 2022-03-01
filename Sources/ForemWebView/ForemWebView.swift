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
    func didLogout(userData: ForemUserData?)
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
    open var userDeviceTokenConfirmed = false

    @objc open dynamic var userData: ForemUserData?

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

    class func isOAuthUrl(_ url: URL) -> Bool {
        url.isOAuthUrl()
    }

    func setupWebView() {
        let messageHandler = ForemScriptMessageHandler(delegate: self)
        configuration.userContentController.add(messageHandler, name: "haptic")
        configuration.userContentController.add(messageHandler, name: "body")
        configuration.userContentController.add(messageHandler, name: "podcast")
        configuration.userContentController.add(messageHandler, name: "imageUpload")
        configuration.userContentController.add(messageHandler, name: "coverUpload")
        configuration.userContentController.add(messageHandler, name: "userLogin")
        configuration.userContentController.add(messageHandler, name: "userLogout")
        if AVPictureInPictureController.isPictureInPictureSupported() {
            configuration.userContentController.add(messageHandler, name: "video")
        }
        allowsBackForwardNavigationGestures = true
        navigationDelegate = self
        uiDelegate = self
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
        return ForemWebView.isOAuthUrl(url)
    }

    // Async callback will return the `ForemUserData` struct, which encapsulates some information
    // regarding the currently logged in user. It will return `nil` if this data isn't available
    open func fetchUserData(completion: @escaping (ForemUserData?) -> Void) {
        let javascript = "window.ForemMobile?.getUserData()"

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
        let javascript = "document.querySelector(`meta[name='csrf-token']`)?.content"
        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            if let error = error {
                print("Unable to fetch CSRF Token: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(result as? String ?? nil)
            }
        }
    }

    // Function that will ensure the ForemWebView is initialized using a valid Forem Instance. It will
    // update `foremInstance` variable which will help provide metadata about the initialized ForemWebView.
    // It will also call `failIfInvalidInstanceError` if unable to populate the metadata on the first load.
    func ensureForemInstance() {
        guard foremInstance == nil else { return }

        let javascript = "window.ForemMobile?.getInstanceMetadata()"

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
