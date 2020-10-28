//
//  ExampleTests.swift
//  ExampleTests
//
//  Created by Fernando Valverde on 9/28/20.
//

import XCTest
import WebKit
@testable import Example

class ExampleTests: XCTestCase {
    
    var viewController: ViewController!

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let userAgentCheck = self.viewController?.webView?.customUserAgent?.contains("ForemWebView")
            XCTAssertTrue(userAgentCheck ?? false, "The UserAgent contains 'ForemWebView' for metrics")
            promise.fulfill()
        }
        wait(for: [promise], timeout: 5)
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
    
    func testDetectsUserStatus() throws {
        _ = viewController.view
//        TODO: Make this test actually work
        
//        let bundle = Bundle(for: type(of: self))
//        let baseURL = URL(string: bundle.resourcePath!)!
//        let loggedInHTML = try? String(contentsOfFile: bundle.path(forResource: "forem.dev", ofType: "html")!)
//        let loggedOutHTML = try? String(contentsOfFile: bundle.path(forResource: "forem.dev-logged-in", ofType: "html")!)
//
//        bundle.path(forResource: "forem.dev", ofType: "html")!
//
//
//        var loggedOutResult: String?
//        let loggedOutExpectation = self.expectation(description: "Logged Out")
//
//        viewController?.webView?.loadHTMLString(loggedInHTML!, baseURL: nil)
//        viewController?.webView?.loadHTMLString(loggedInHTML!, baseURL: nil)
//        viewController?.webView?.loadHTMLString(loggedInHTML!, baseURL: nil)
//        viewController?.webView?.evaluateJavaScript("document.documentElement.outerHTML.toString()") { html, err in
//            print(html)
//            loggedOutExpectation.fulfill()
//        }
//        viewController?.webView?.fetchUserStatus { status in
//            loggedOutResult = status
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//        XCTAssertEqual(loggedOutResult, "logged-out")
//
//        var loggedInResult: String?
//        let loggedInExpectation = self.expectation(description: "Logged In")
//        viewController?.webView?.loadHTMLString(loggedInHTML!, baseURL: bundle.bundleURL)
//        viewController?.webView?.fetchUserStatus { status in
//            loggedInResult = status
//            loggedInExpectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//        XCTAssertEqual(loggedInResult, "logged-out")
    }
}
