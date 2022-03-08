import XCTest
@testable import ForemWebView

final class ForemWebViewTests: XCTestCase {
    // These values need to be tuned for CI performance. Keep in mind that locally you may be
    // running on better specs than CI will be using to run these, that's the reason behind them
    // being large (forgiving). It would be good to find a way to avoid having to do the async dispatches
    let asyncAfter = 7.0
    let timeout = 15.0
    
    let loggedOutHTML: String = {
        let fileURL = Bundle.module.url(forResource: "forem.dev", withExtension: "html")!
        return try! String(contentsOf: fileURL.absoluteURL)
    }()
    let loggedInHTML: String = {
        let fileURL = Bundle.module.url(forResource: "logged-in-forem.dev", withExtension: "html")!
        return try! String(contentsOf: fileURL.absoluteURL)
    }()
    
    static var allTests = [
        ("testCustomUserAgent", testCustomUserAgent),
        ("testAuthURLs", testAuthURLs),
        ("testUserDataIsNilWhenLoggedOut", testUserDataIsNilWhenLoggedOut),
        ("testExtractsUserDataWithDefaultTheme", testExtractsUserDataWithDefaultTheme),
    ]
    
    func testCustomUserAgent() {
        let webView = ForemWebView()
        webView.loadHTMLString(loggedOutHTML, baseURL: nil)
        
        let promise = expectation(description: "Custom UserAgent")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
                guard let userAgent = result as? String else { return }
                let userAgentCheck = userAgent.contains("ForemWebView")
                XCTAssertTrue(userAgentCheck, "The UserAgent contains 'ForemWebView' for identification purposes")
                promise.fulfill()
            }
        }
        wait(for: [promise], timeout: timeout)
    }
    
    func testAuthURLs() {
        let webView = ForemWebView()

        let urlStrings = [
            "https://github.com/login",
            "https://github.com/sessions/two-factor",
            """
                https://github.com/login?client_id=123123123123&
                return_to=%2Flogin%2Foauth%2Fauthorize%3Fclient_id%3Dd7251d40ac9298bdd9fe%26redirect_uri%3D
                https%253A%252F%252Fdev.to%252Fusers%252Fauth%252Fgithub%252Fcallback%26response_type%3D
                code%26scope%3Duser%253Aemail%26state%3Dfb251bee9df12312312313d6e228bdc63
            """,
            "https://api.twitter.com/oauth",
            "https://api.twitter.com/oauth/authenticate?oauth_token=-_1DwgA123123123YqVY",
            """
                https://twitter.com/login/error?username_or_email=asdasda&redirect_after_login=
                https%3A%2F%2Fapi.twitter.com%2Foauth%2Fauthenticate%3Foauth_token%3D-_1DwgAAAAAAa8cGAAABdXEYqVY
            """,
            "https://www.facebook.com/v4.0/dialog/oauth",
            "https://www.facebook.com/v5.9/dialog/oauth",
            "https://www.facebook.com/v6.0/dialog/oauth",
            "https://m.facebook.com/v4.0/dialog/oauth",
            "https://m.facebook.com/v6.0/dialog/oauth",
            "https://m.facebook.com/login.php?skip_api_login=1&api_key=asdf",
            "https://account.forem.com/oauth/authorize?client_id=IBex_ltWo0tiuoB9CgHt7LCrwTuG5rlwhphjzQdf1RA&redirect_uri=https%3A%2F%2Fgggames.visualcosita.com%2Fusers%2Fauth%2Fforem%2Fcallback&response_type=code&state=de3f6b0c4cac41fdb9abf5409ce2f24e2d743245ca37a53a"
        ]
        for urlString in urlStrings {
            if let url = URL(string: urlString) {
                XCTAssertTrue(webView.isOAuthUrl(url), "String didn't match as Auth URL: \(urlString)")
            }
        }
    }
    
    func testUserDataIsNilWhenLoggedOut() {
        let webView = ForemWebView()
        webView.loadHTMLString(loggedOutHTML, baseURL: nil)

        let promise = expectation(description: "UserData is nil when unauthenticated")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            webView.fetchUserData { (userData) in
                XCTAssertNil(userData?.theme())
                promise.fulfill()
            }
        }

        wait(for: [promise], timeout: timeout)
    }

    func testExtractsUserDataWithDefaultTheme() {
        let webView = ForemWebView()
        webView.loadHTMLString(loggedInHTML, baseURL: nil)

        let promise = expectation(description: "UserData with default theme")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            webView.fetchUserData { (userData) in
                XCTAssertTrue(userData?.theme() == .base)
                promise.fulfill()
            }
        }

        wait(for: [promise], timeout: timeout)
    }
}
