#if os(iOS)

import UIKit

extension ForemWebView {
    open func registerDevice(token: String) {
        guard !userDeviceTokenConfirmed, let appBundle = Bundle.main.bundleIdentifier else { return }
        let javascript = """
                            window.registerDeviceToken = () => {
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
                                }).then(response => response.json()).then((data) => {
                                    if (data.id) {
                                        // Clear the interval if the registration succeeded
                                        clearInterval(window.deviceRegistrationInterval);
                                    } else {
                                        throw new Error("REQUEST FAILED");
                                    }
                                }).catch((error) => {
                                    // Re-attempt with exponential backoff up to ~10s delay
                                    clearInterval(window.deviceRegistrationInterval);
                                    if (window.deviceRegistrationMs < 10000) {
                                        window.deviceRegistrationMs = window.deviceRegistrationMs * 2;
                                    }

                                    console.log(`Error registering Device Token. Next attempt in ${window.deviceRegistrationMs/1.0}s`);
                                    window.deviceRegistrationInterval = setInterval(
                                        window.registerDeviceToken,
                                        window.deviceRegistrationMs
                                    );

                                    // Force a refresh on BaseData (CSRF Token)
                                    fetchBaseData();
                                });
                            }

                            window.deviceRegistrationMs = 500;
                            window.deviceRegistrationInterval = setInterval(
                                window.registerDeviceToken,
                                window.deviceRegistrationMs
                            );
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
