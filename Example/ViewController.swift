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

        // Observations need to be retained in order for them to work
        observations = [
            webView.observe(\ForemWebView.userData, options: .new) { (webView, _) in
                if let userData = webView.userData {
                    print("UserID [config_body_class]: \(userData.userID) [\(userData.configBodyClass)]")
                } else {
                    print("User Logged out")
                }
            },
            webView.observe(\ForemWebView.estimatedProgress, options: .new) { (webView, _) in
                self.progressView.progress = Float(webView.estimatedProgress)
            }
        ]
    }
}

extension ViewController: ForemWebViewDelegate {
    func willStartNativeVideo(playerController: AVPlayerViewController) {
        if playerController.presentingViewController == nil {
            present(playerController, animated: true) {
                playerController.player?.play()
            }
        }
    }

    func requestedExternalSite(url: URL) {
        // You can open a custom WKWebView for external sites, present SFSafariViewController, etc.
        print("This was the external site requested: \(url.absoluteString)")
    }

    func requestedMailto(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            // Should open the default Mail app
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func didStartNavigation() {
        activityIndicator.isHidden = false
        progressView.progress = 0
        progressView.isHidden = false
    }

    func didFinishNavigation() {
        activityIndicator.isHidden = true
        progressView.isHidden = true
    }
}
