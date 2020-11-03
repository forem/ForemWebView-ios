import WebKit

extension ForemWebView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        foremWebViewDelegate?.didStartNavigation()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        ensureForemInstance()
        ensureMutationObserver()
        foremWebViewDelegate?.didFinishNavigation()
    }

    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let policy = navigationPolicy(url: url, navigationType: navigationAction.navigationType)
        decisionHandler(policy)
    }

    // MARK: - Action Policy
    func navigationPolicy(url: URL, navigationType: WKNavigationType) -> WKNavigationActionPolicy {
        if foremInstance == nil {
            // First load there will be no Instance Metadata available
            return .allow
        } else if url.scheme == "mailto" {
            foremWebViewDelegate?.requestedExternalSite(url: url)
            return .cancel
        } else if url.absoluteString == "about:blank" {
            return .allow
        } else if isOAuthUrl(url) {
            return .allow
        } else if url.host != foremInstance?.domain && navigationType.rawValue == 0 {
            foremWebViewDelegate?.requestedExternalSite(url: url)
            return .cancel
        } else {
            return .allow
        }
    }
}
