#if os(iOS)

import UIKit
import WebKit

extension ForemWebView: WKUIDelegate {
    public func webView(_ webView: WKWebView,
                        runJavaScriptConfirmPanelWithMessage message: String,
                        initiatedByFrame frame: WKFrameInfo,
                        completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)
        
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                completionHandler(false)
            }
        )
        
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
                completionHandler(true)
            }
        )
        
        // Use 'foremWebViewDelegate' as the 'pivot' ViewController to present the native picker
        if let delegateViewController = foremWebViewDelegate as? UIViewController {
            delegateViewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    public func webView(_ webView: WKWebView,
                        runJavaScriptAlertPanelWithMessage message: String,
                        initiatedByFrame frame: WKFrameInfo,
                        completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)
        
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
                completionHandler()
            }
        )
        
        // Use 'foremWebViewDelegate' as the 'pivot' ViewController to present the native picker
        if let delegateViewController = foremWebViewDelegate as? UIViewController {
            delegateViewController.present(alertController, animated: true, completion: nil)
        }
    }
}

#endif
