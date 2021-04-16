#if os(iOS)

import UIKit

extension ForemWebView {
    open func registerDevice(token: String) {
        guard !userDeviceTokenConfirmed, let appBundle = Bundle.main.bundleIdentifier else { return }
        let javascript = """
                            var waitingForDataLoad = setInterval(function wait() {
                                if (window.csrfToken) {
                                  const params = JSON.stringify({
                                      "token": "\(token)",
                                      "platform": "iOS",
                                      "app_bundle": "\(appBundle)"
                                  })
                                  fetch("/users/devices", {
                                      method: 'POST',
                                      headers: {
                                        Accept: 'application/json',
                                        'X-CSRF-Token': window.csrfToken,
                                        'Content-Type': 'application/json',
                                      },
                                      body: params,
                                      credentials: 'same-origin',
                                  }).then((response) => {
                                      // Clear the interval if the registration succeeded
                                      if (response.status === 200) {
                                        clearInterval(waitingForDataLoad);
                                      }
                                  })
                                }
                              }, 3000);
                            null
                         """
        
        evaluateJavaScript(javascript) { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.userDeviceTokenConfirmed = true
            }
        }
    }
    
    open func unregisterDevice(token: String, userID: Int) {
        guard userDeviceTokenConfirmed, let appBundle = Bundle.main.bundleIdentifier else { return }
        let javascript = """
                            const params = JSON.stringify({
                                "token": "\(token)",
                                "platform": "iOS",
                                "app_bundle": "\(appBundle)"
                            })
                            fetch("/users/devices/\(userID)", {
                                method: 'DELETE',
                                headers: {
                                  Accept: 'application/json',
                                  'Content-Type': 'application/json',
                                },
                                body: params,
                            })
                            null
                         """
        
        evaluateJavaScript(javascript) { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.userDeviceTokenConfirmed = false
            }
        }
    }
}

#endif
