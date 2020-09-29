//
//  ViewController.swift
//  Example
//
//  Created by Fernando Valverde on 9/28/20.
//

import UIKit
import AVKit
import WebKit
import ForemWebView

class ViewController: UIViewController {

    @IBOutlet weak var webView: ForemWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.setup(navigationDelegate: self, foremWebViewDelegate: self)
        webView.load("https://dev.to")
    }
}

extension ViewController: ForemWebViewDelegate {
    func willStartNativeVideo(playerController: AVPlayerViewController) {
        present(playerController, animated: true) {
            playerController.player?.play()
        }
    }
}

extension ViewController: WKNavigationDelegate {
    func navigationPolicy(url: URL, navigationType: WKNavigationType) -> WKNavigationActionPolicy {
        if url.absoluteString == "about:blank" {
            return .allow
        } else if webView.isOAuthUrl(url) {
            return .allow
        } else if url.host != webView.baseHost && navigationType.rawValue == 0 {
            // Use this to open a modal or handle the external link
            // performSegue(withIdentifier: DoAction.openExternalURL, sender: url)
            return .cancel
        } else {
            return .allow
        }
    }
}
