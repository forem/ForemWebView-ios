#if os(iOS)

import UIKit

extension ForemWebView {
    open func cachedPreview() -> ForemWebViewCachedState? {
        guard let customURL = url?.absoluteString,
              let snapshot = snapshotView(afterScreenUpdates: true) else {
            return nil
        }
        
        var scrollPoint = convert(CGPoint(x: 0, y: 0), to: scrollView)
        scrollPoint = CGPoint(x: scrollPoint.x, y: scrollView.contentSize.height - frame.size.height)
        print("HMMMM: \(scrollView.contentSize.height), \(frame.size.height)")

        return ForemWebViewCachedState(customURL: customURL,
                                       snapshot: snapshot,
                                       scrollOffset: scrollPoint)
    }
}

#endif
