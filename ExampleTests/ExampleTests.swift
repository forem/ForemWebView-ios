import XCTest
import WebKit
@testable import Example

class ExampleTests: XCTestCase {
    
    var viewController: ViewController!
    
    // These values need to be tuned for CI performance. Keep in mind that locally you may be
    // running on better specs than CI will be using to run these, that's the reason behind them
    // being large (forgiving). It would be good to find a way to avoid having to do the async dispatches
    let asyncAfter = 4.0
    let timeout = 15.0

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        viewController = mainStoryboard.instantiateInitialViewController() as? ViewController
        viewController?.webView?.load("forem.dev.html")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCustomUserAgent() throws {
        _ = viewController.view
        let promise = expectation(description: "Custom UserAgent")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            let userAgentCheck = self.viewController?.webView?.customUserAgent?.contains("ForemWebView")
            XCTAssertTrue(userAgentCheck ?? false, "The UserAgent contains 'ForemWebView' for metrics")
            promise.fulfill()
        }
        wait(for: [promise], timeout: timeout)
    }
    
    func testAuthUrlCheck() throws {
        _ = viewController.view
        guard let webView = self.viewController?.webView else { return }
        
        let urlStrings = [
            "https://github.com/login",
            "https://github.com/sessions/two-factor",
            "https://github.com/login?client_id=123123123123&return_to=%2Flogin%2Foauth%2Fauthorize%3Fclient_id%3Dd7251d40ac9298bdd9fe%26redirect_uri%3Dhttps%253A%252F%252Fdev.to%252Fusers%252Fauth%252Fgithub%252Fcallback%26response_type%3Dcode%26scope%3Duser%253Aemail%26state%3Dfb251bee9df12312312313d6e228bdc63",
            "https://api.twitter.com/oauth",
            "https://api.twitter.com/oauth/authenticate?oauth_token=-_1DwgA123123123YqVY",
            "https://twitter.com/login/error?username_or_email=asdasda&redirect_after_login=https%3A%2F%2Fapi.twitter.com%2Foauth%2Fauthenticate%3Foauth_token%3D-_1DwgAAAAAAa8cGAAABdXEYqVY",
            "https://www.facebook.com/v4.0/dialog/oauth",
            "https://www.facebook.com/v5.9/dialog/oauth",
            "https://www.facebook.com/v6.0/dialog/oauth",
        ]
        for urlString in urlStrings {
            if let url = URL(string: urlString) {
                XCTAssertTrue(webView.isOAuthUrl(url), "String didn't match as Auth URL: \(urlString)")
            }
        }
    }
    
    func testDetectsUserStatusLoggedIn() throws {
        _ = viewController.view
        guard let webView = self.viewController?.webView else { return }
        let bundle = Bundle(for: type(of: self))
        let html = try! String(contentsOfFile: bundle.path(forResource: "forem.dev-logged-in", ofType: "html")!)
        
        webView.loadHTMLString(html, baseURL: nil)
        let promise = expectation(description: "Custom UserAgent")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            webView.fetchUserStatus { (status) in
                XCTAssertTrue(status == "logged-in")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: timeout)
    }
    
    func testDetectsUserStatus() throws {
        _ = viewController.view
        guard let webView = self.viewController?.webView else { return }
        let bundle = Bundle(for: type(of: self))
        let html = try! String(contentsOfFile: bundle.path(forResource: "forem.dev", ofType: "html")!)
        
        webView.loadHTMLString(html, baseURL: nil)
        let promise = expectation(description: "Custom UserAgent")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            webView.fetchUserStatus { (status) in
                XCTAssertTrue(status == "logged-out")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: timeout)
    }
    
    func testUserDataIsNilWhenLoggedOut() throws {
        _ = viewController.view
        guard let webView = self.viewController?.webView else { return }
        let bundle = Bundle(for: type(of: self))
        let html = try! String(contentsOfFile: bundle.path(forResource: "forem.dev", ofType: "html")!)
        
        webView.loadHTMLString(html, baseURL: nil)
        let promise = expectation(description: "Custom UserAgent")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            webView.fetchUserData { (userData) in
                XCTAssertNil(userData?.theme())
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: timeout)
    }
    
    func testExtractsUserDataWithDefaultTheme() throws {
        _ = viewController.view
        guard let webView = self.viewController?.webView else { return }
        let bundle = Bundle(for: type(of: self))
        let html = try! String(contentsOfFile: bundle.path(forResource: "forem.dev-logged-in", ofType: "html")!)
        
        webView.loadHTMLString(html, baseURL: nil)
        let promise = expectation(description: "Custom UserAgent")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            webView.fetchUserData { (userData) in
                XCTAssertTrue(userData?.theme() == "default")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: timeout)
    }
    
    func testExtractsUserDataWithPinkTheme() throws {
        _ = viewController.view
        guard let webView = self.viewController?.webView else { return }
        let bundle = Bundle(for: type(of: self))
        let html = try! String(contentsOfFile: bundle.path(forResource: "forem.dev-logged-in-pink", ofType: "html")!)
        
        webView.loadHTMLString(html, baseURL: nil)
        let promise = expectation(description: "Custom UserAgent")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            webView.fetchUserData { (userData) in
                XCTAssertTrue(userData?.theme() == "pink-theme")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: timeout)
    }
    
    func testExtractsUserDataWithNightTheme() throws {
        _ = viewController.view
        guard let webView = self.viewController?.webView else { return }
        let bundle = Bundle(for: type(of: self))
        let html = try! String(contentsOfFile: bundle.path(forResource: "forem.dev-logged-in-dark", ofType: "html")!)
        
        webView.loadHTMLString(html, baseURL: nil)
        let promise = expectation(description: "Custom UserAgent")
        // On top of the expectation it turns out we need to give the webView some time to load/process the HTML string
        DispatchQueue.main.asyncAfter(deadline: .now() + asyncAfter) {
            webView.fetchUserData { (userData) in
                XCTAssertTrue(userData?.theme() == "night-theme")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: timeout)
    }
}
