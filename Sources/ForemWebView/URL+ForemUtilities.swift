import Foundation

extension URL {
    var isGoogleAuth: Bool { self.absoluteString.starts(with: "https://accounts.google.com") }
    
    var isFacebookAuth: Bool {
        (self.absoluteString.starts(with: "https://facebook.com") || self.absoluteString.starts(with: "https://m.facebook.com")) && self.absoluteString.contains("/dialog/oauth?")
    }
}
