//
//  ExampleTests.swift
//  ExampleTests
//
//  Created by Fernando Valverde on 9/28/20.
//

import XCTest
@testable import Example

class ExampleTests: XCTestCase {
    
    var viewController: ViewController!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        viewController = mainStoryboard.instantiateInitialViewController() as? ViewController
        viewController?.webView.load("forem.dev.html")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func customUserAgent() throws {
        XCTAssertEqual(viewController?.webView?.customUserAgent, "forem-ios")
    }
    
    func detectsUserStatus() throws {
        viewController?.webView?.fetchUserStatus { status in
            XCTAssertEqual(status, "logged-out")
        }
        
        viewController?.webView?.load("forem.dev-logged-in.html")
        viewController?.webView?.fetchUserStatus { status in
            XCTAssertEqual(status, "logged-in")
        }
    }
}
