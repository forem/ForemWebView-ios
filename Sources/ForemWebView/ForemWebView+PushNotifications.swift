//
//  File.swift
//  
//
//  Created by Fernando Valverde on 20/1/21.
//

import UIKit

extension ForemWebView {
    open func registerDevice(token: String) {
        guard !userDeviceTokenConfirmed else { return }
        let javascript = """
                            fetch("/users/devices", {
                                method: 'POST',
                                headers: {
                                  Accept: 'application/json',
                                  'X-CSRF-Token': window.csrfToken,
                                  'Content-Type': 'application/json',
                                },
                                body: JSON.stringify({ "token": "\(token)" }),
                                credentials: 'same-origin',
                            })
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
        guard userDeviceTokenConfirmed else { return }
        let javascript = """
                            fetch("/users/devices/\(userID)", {
                                method: 'DELETE',
                                headers: {
                                  Accept: 'application/json',
                                  'X-CSRF-Token': window.csrfToken,
                                  'Content-Type': 'application/json',
                                },
                                body: JSON.stringify({ "token": "\(token)" }),
                                credentials: 'same-origin',
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
