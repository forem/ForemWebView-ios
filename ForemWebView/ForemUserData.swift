import Foundation

@objc public class ForemUserData: NSObject, Codable {
    enum CodingKeys: String, CodingKey {
        case userID = "id"
        case configBodyClass = "config_body_class"
    }
    public var userID: Int
    public var configBodyClass: String

    // Returns the UX theme in the logged-in user's settings
    public func theme() -> String {
        let regex = #".+-theme"#
        for element in configBodyClass.split(separator: " ") {
            if let range = element.range(of: regex, options: .regularExpression) {
                return String(element[range])
            }
        }
        return "default"
    }

    public static func isEqual(lfi: ForemUserData, rfi: ForemUserData) -> Bool {
        return (lfi.userID == rfi.userID) && (lfi.configBodyClass == rfi.configBodyClass)
    }
}
