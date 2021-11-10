#if os(iOS)

import UIKit

extension ForemWebView {
    open func registerDevice(token: String) {
        guard !userDeviceTokenConfirmed, let appBundle = Bundle.main.bundleIdentifier else { return }
        let javascript = "window.ForemMobile?.registerDeviceToken('\(token)', '\(appBundle)', 'iOS')"

        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.userDeviceTokenConfirmed = true
            }
        }
    }
    
    open func unregisterDevice(token: String, userID: Int) {
        guard userDeviceTokenConfirmed, let appBundle = Bundle.main.bundleIdentifier else { return }
        let javascript = "window.ForemMobile?.unregisterDeviceToken('\(userID)', '\(token)', '\(appBundle)', 'iOS')"

        evaluateJavaScript(wrappedJS(javascript)) { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.userDeviceTokenConfirmed = false
            }
        }
    }
}

#endif
