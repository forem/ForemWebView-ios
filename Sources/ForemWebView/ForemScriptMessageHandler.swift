#if os(iOS)

import UIKit
import WebKit

class ForemScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate : WKScriptMessageHandler?
    
    init(delegate:WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
}

#endif
