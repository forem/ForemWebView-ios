//
//  File.swift
//  
//
//  Created by Fernando Valverde on 20/1/21.
//

import UIKit
import Alamofire

extension ForemWebView {
    open func registerDeviceForPN(token: String) {
        guard let csrfToken = csrfToken,
              let domain = foremInstance?.domain else { return }

        AF.request("https://\(domain)/users/devices",
                   method: .post,
                   parameters: [ "token": token ],
                   headers: [ "X-CSRF-Token": csrfToken ]).responseJSON { (response) in
            
            guard let statusCode = response.response?.statusCode else {
                puts("ERRORRRRRRR")
                return
            }

            if statusCode == 200, let result = response.value as? [String: [String]] {
                print("SUCCESS")
            } else if let error = response.error {
                print(error.localizedDescription)
            } else {
                print("Unexpected error")
            }
        }
    }
    
    open func unregisterDeviceForPN(token: String) {
        guard let csrfToken = csrfToken,
              let domain = foremInstance?.domain,
              let userID = userData?.userID else { return }

        AF.request("https://\(domain)/users/devices/\(userID)",
                   method: .delete,
                   parameters: [ "token": token ],
                   headers: [ "X-CSRF-Token": csrfToken ]).responseJSON { (response) in
            
            guard let statusCode = response.response?.statusCode else {
                puts("ERRORRRRRRR")
                return
            }

            if statusCode == 200, let result = response.value as? [String: [String]] {
                print("SUCCESS")
            } else if let error = response.error {
                print(error.localizedDescription)
            } else {
                print("Unexpected error")
            }
        }
    }
}
