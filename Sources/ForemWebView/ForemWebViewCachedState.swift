#if os(iOS)

import UIKit
import WebKit
import Foundation

public struct ForemWebViewCachedState {
    public var customURL: String
    public var snapshot: UIView
    public var scrollOffset: CGPoint
}

#endif
