import XCTest
import Fakery

class URL_ForemUtilitiesTests: XCTestCase {

    static var allTests = [
        ("testIsOauthURL", testIsOauthURL),
        ("testIsGoogleAuth", testIsGithubAuth),
        ("testIsGithubAuth", testIsGoogleAuth),
        ("testIsFacebookAuth", testIsFacebookAuth),
        ("testIsForemPassportAuth", testIsForemPassportAuth),
        ("testIsTwitterAuth", testIsTwitterAuth),
    ]
    static let faker = Faker()
    
    static let githubUrlStrings = [
        "https://github.com/login",
        "https://github.com/sessions/two-factor",
        """
            https://github.com/login?client_id=123123123123&
            return_to=%2Flogin%2Foauth%2Fauthorize%3Fclient_id%3Dd7251d40ac9298bdd9fe%26redirect_uri%3D
            https%253A%252F%252Fdev.to%252Fusers%252Fauth%252Fgithub%252Fcallback%26response_type%3D
            code%26scope%3Duser%253Aemail%26state%3Dfb251bee9df12312312313d6e228bdc63
        """,
    ]
    
    static let twitterUrlStrings = [
        "https://api.twitter.com/oauth",
        "https://api.twitter.com/oauth/authenticate?oauth_token=-_1DwgA123123123YqVY",
        """
            https://twitter.com/login/error?username_or_email=asdasda&redirect_after_login=
            https%3A%2F%2Fapi.twitter.com%2Foauth%2Fauthenticate%3Foauth_token%3D-_1DwgAAAAAAa8cGAAABdXEYqVY
        """,
    ]
    
    static let facebookUrlStrings = [
        "https://www.facebook.com/v4.0/dialog/oauth",
        "https://www.facebook.com/v5.9/dialog/oauth",
        "https://www.facebook.com/v6.0/dialog/oauth",
        "https://m.facebook.com/v4.0/dialog/oauth",
        "https://m.facebook.com/v6.0/dialog/oauth",
        "https://m.facebook.com/login.php?skip_api_login=1&api_key=asdf",
    ]
    
    static let passportUrlStrings = [
        "https://passport.forem.com/oauth/authorize?client_id=IBex_ltWo0tiuoB9CgHt7LCrwTuG5rlwhphjzQdf1RA&redirect_uri=https%3A%2F%2Fgggames.visualcosita.com%2Fusers%2Fauth%2Fforem%2Fcallback&response_type=code&state=de3f6b0c4cac41fdb9abf5409ce2f24e2d743245ca37a53a"
    ]
    
    static let googleUrlStrings = [
        "https://accounts.google.com/o/oauth2/v2/auth",
        """
            https://accounts.google.com/o/oauth2/v2/auth?
             scope=https%3A//www.googleapis.com/auth/drive.metadata.readonly&
             access_type=offline&
             include_granted_scopes=true&
             response_type=code&
             state=state_parameter_passthrough_value&
             redirect_uri=https%3A//oauth2.example.com/code&
             client_id=client_id
        """,
    ]
    
    static let urlStrings = githubUrlStrings + twitterUrlStrings + facebookUrlStrings + passportUrlStrings + googleUrlStrings
    
    func testIsOauthURL() {
        for urlString in URL_ForemUtilitiesTests.urlStrings {
            if let url = URL(string: urlString) {
                XCTAssertTrue(url.isOAuthUrl(), "String didn't match as Auth URL: \(urlString)")
            }
        }
        
        for _ in 0...5 {
            if let url = URL(string: URL_ForemUtilitiesTests.faker.internet.url()) {
                XCTAssertFalse(url.isOAuthUrl(), "String incorrectly identified a Auth URL: \(url.absoluteString)")
            }
        }
    }
    
    func testIsGithubAuth() {
        for urlString in URL_ForemUtilitiesTests.githubUrlStrings {
            if let url = URL(string: urlString) {
                XCTAssertTrue(url.isGithubAuth, "String didn't match as Auth URL: \(urlString)")
            }
        }
    }
    
    func testIsGoogleAuth() {
        for urlString in URL_ForemUtilitiesTests.googleUrlStrings {
            if let url = URL(string: urlString) {
                XCTAssertTrue(url.isGoogleAuth, "String didn't match as Auth URL: \(urlString)")
            }
        }
    }

    func testIsFacebookAuth() {
        for urlString in URL_ForemUtilitiesTests.facebookUrlStrings {
            if let url = URL(string: urlString) {
                XCTAssertTrue(url.isFacebookAuth, "String didn't match as Auth URL: \(urlString)")
            }
        }
    }

    func testIsForemPassportAuth() {
        for urlString in URL_ForemUtilitiesTests.passportUrlStrings {
            if let url = URL(string: urlString) {
                XCTAssertTrue(url.isForemPassportAuth, "String didn't match as Auth URL: \(urlString)")
            }
        }
    }
    
    func testIsTwitterAuth() {
        for urlString in URL_ForemUtilitiesTests.twitterUrlStrings {
            if let url = URL(string: urlString) {
                XCTAssertTrue(url.isTwitterAuth, "String didn't match as Auth URL: \(urlString)")
            }
        }
    }

}
