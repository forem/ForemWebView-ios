#if os(iOS)

import UIKit

extension ForemWebView {
    open func cachedPreview() -> ForemWebViewCachedState? {
        guard let customURL = url?.absoluteString,
              let snapshot = snapshotView(afterScreenUpdates: true) else {
            return nil
        }

        let scrollOffsetExcemptPaths = [
            "/",
            "/latest",
            "/top/week",
            "/top/month",
            "/top/infinity",
        ]
        var scrollOffset = scrollView.contentOffset
        if scrollOffsetExcemptPaths.contains(url?.relativePath ?? "") {
            // Excempt paths (main feed) should have a scroll offset of 0
            // More about this here: https://github.com/forem/forem-ios/issues/112
            scrollOffset = CGPoint.zero
        }

        return ForemWebViewCachedState(customURL: customURL,
                                       snapshot: snapshot,
                                       scrollOffset: scrollOffset)
    }
}

#endif
