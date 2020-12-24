#if os(iOS)

import WebKit

extension ForemWebView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        foremWebViewDelegate?.didStartNavigation()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //Remove scroll if /connect view
        webView.scrollView.isScrollEnabled = !(webView.url?.path.hasPrefix("/connect") ?? false)
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
