import Foundation

public extension URL {
    // Regex for Facebook OAuth based on their API versions
    // Example: "https://www.facebook.com/v4.0/dialog/oauth"
    static let faceBookRegex =  #"https://(www|m)?\.facebook\.com/(v\d+.\d+/dialog/oauth|login.php)"#
    var isFacebookAuth: Bool {
        self.absoluteString.range(of: URL.faceBookRegex, options: .regularExpression) != nil
    }
    
    // Forem Account Auth
    var isForemAccountAuth: Bool { self.absoluteString.hasPrefix("https://account.forem.com/oauth") }
    
    // GitHub OAuth paths including 2FA + error pages
    var isGithubAuth: Bool {
        self.absoluteString.hasPrefix("https://github.com/login") ||
        self.absoluteString.hasPrefix("https://github.com/session")
    }
    
    //Google OAuth pages
    var isGoogleAuth: Bool { self.absoluteString.hasPrefix("https://accounts.google.com") }
    
    // Twitter OAuth paths including error pages
    var isTwitterAuth: Bool {
        self.absoluteString.hasPrefix("https://api.twitter.com/oauth") ||
        self.absoluteString.hasPrefix("https://twitter.com/login/error")
    }
    
    
    func isOAuthUrl() -> Bool {
    

        if isGithubAuth {
            return true
        }

        if isTwitterAuth {
            return true
        }
        
        if isFacebookAuth {
            return true
        }
        
        if isGoogleAuth {
            return true
        }

        if isForemAccountAuth {
            return true
        }

        // Didn't match any supported OAuth URL
        return false
    }
}
