#if os(iOS)

import WebKit

extension ForemWebView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        foremWebViewDelegate?.didStartNavigation()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let cachedState = self.cachedState {
            scrollView.setContentOffset(cachedState.scrollOffset, animated: false)
            UIView.animate(withDuration: 0.5) {
                cachedState.snapshot.alpha = 0
            } completion: { [weak self] _ in
                cachedState.snapshot.removeFromSuperview()
                self?.cachedState = nil
            }
        }
        
        //Remove scroll if /connect view
        webView.scrollView.isScrollEnabled = !(webView.url?.path.hasPrefix("/connect") ?? false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Trying to give these functions some async time for the environment
            // to become fully initialized on the first load after app boot
            self.ensureForemInstance()
            self.foremWebViewDelegate?.didFinishNavigation()
        }
    }

    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let policy = navigationPolicy(url: url, navigationType: navigationAction.navigationType)
        
        // target="_blank" normal navigation won't work and in order for the webview to follow
        // these links (specially within an iframe) requires us to capture the navigation and
        // `.cancel` it, then manually loading the URL.
        if policy == .allow && navigationAction.targetFrame == nil {
            decisionHandler(.cancel)
            load(url.absoluteString)
        } else {
            decisionHandler(policy)
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        foremWebViewDelegate?.didFailNavigation()
    }

    // MARK: - Action Policy
    func navigationPolicy(url: URL, navigationType: WKNavigationType) -> WKNavigationActionPolicy {
        guard let foremInstance = foremInstance else {
            // First load there will be no Instance Metadata available
            return .allow
        }

        if url.scheme == "mailto" {
            foremWebViewDelegate?.requestedMailto(url: url)
            return .cancel
        } else if url.absoluteString == "about:blank" {
            return .allow
        } else if isOAuthUrl(url) {
            return .allow
        }

        // localhost gives simulator support with a local server running
        let isExternalDomain = (url.host != foremInstance.domain) && (url.host != "localhost")
        if isExternalDomain && navigationType == .linkActivated {
            foremWebViewDelegate?.requestedExternalSite(url: url)
            return .cancel
        } else {
            return .allow
        }
    }
}

#endif
