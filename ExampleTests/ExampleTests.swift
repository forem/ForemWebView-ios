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
