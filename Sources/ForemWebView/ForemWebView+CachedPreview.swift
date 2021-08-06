#if os(iOS)

import UIKit

extension ForemWebView {
    open func cachedPreview() -> ForemWebViewCachedState? {
        guard let customURL = url?.absoluteString,
              let snapshot = snapshotView(afterScreenUpdates: true) else {
            return nil
        }
        
        return ForemWebViewCachedState(customURL: customURL, snapshot: snapshot)
    }
}

#endif
