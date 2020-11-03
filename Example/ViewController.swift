import UIKit
import AVKit
import WebKit
import ForemWebView

class ViewController: UIViewController {

    @IBOutlet weak var webView: ForemWebView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var observations: [NSKeyValueObservation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.foremWebViewDelegate = self
        webView.load("https://dev.to")
        activityIndicator.startAnimating()
        observations = [
            webView.observe(\ForemWebView.userData, options: .new, changeHandler: { (webView, _) in
                if let userData = webView.userData {
                    print("UserID [config_body_class]: \(userData.userID) [\(userData.configBodyClass)]")
                } else {
                    print("User Logged out")
                }
            }),
            webView.observe(\ForemWebView.estimatedProgress, options: .new, changeHandler: { (webView, _) in
                self.progressView.progress = Float(webView.estimatedProgress)
            })
        ]
    }
}

extension ViewController: ForemWebViewDelegate {
    func willStartNativeVideo(playerController: AVPlayerViewController) {
        present(playerController, animated: true) {
            playerController.player?.play()
        }
    }
    
    func requestedExternalSite(url: URL) {
        print("This was the external site requested: \(url.absoluteString)")
        // You can open a custom WKWebView for external sites, present SFSafariViewController, etc.
    }
    
    func requestedMailto(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func didStartNavigation() {
        activityIndicator.isHidden = false
        progressView.progress = 0
    }
    
    func didFinishNavigation() {
        activityIndicator.isHidden = true
        progressView.progress = 0
    }
}
