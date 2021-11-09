#if os(iOS)

import Foundation

@objc public class ForemUserData: NSObject, Codable {
    enum CodingKeys: String, CodingKey {
        case userID = "id"
        case configBodyClass = "config_body_class"
    }
    public var userID: Int
    public var configBodyClass: String

    public init(message: [String: Any]) {
        if let userIDStr = message["id"] as? Int, let bodyClass = message["config_body_class"] as? String {
            userID = Int(userIDStr) ?? 0
            configBodyClass = bodyClass
        } else {
            userID = 0
            configBodyClass = ""
        }
    }

    // Returns the UX theme in the logged-in user's settings
    public func theme() -> ForemWebViewTheme {
        var themeName = ""
        let regex = #".+-theme"#
        for element in configBodyClass.split(separator: " ") {
            if let range = element.range(of: regex, options: .regularExpression) {
                themeName = String(element[range])
            }
        }

        switch themeName {
        case "night-theme":
            return .night
        case "minimal-light-theme":
            return .minimal
        case "pink-theme":
            return .pink
        case "ten-x-hacker-theme":
            return .hacker
        default:
            return .base
        }
    }

    public static func isEqual(lfi: ForemUserData, rfi: ForemUserData) -> Bool {
        return (lfi.userID == rfi.userID) && (lfi.configBodyClass == rfi.configBodyClass)
    }
}

#endif
