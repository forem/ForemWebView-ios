//
//  UIImage+Resize.swift
//  ForemWebView
//
//  Created by Fernando Valverde on 12/10/20.
//

import UIKit

extension UIImage {
    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func uploadToForem(uploadUrl: String, token: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: uploadUrl), let uploadData = pngData() else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "X-CSRF-Token")
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "authenticity_token": token,
            "image[]": uploadData
        ]
        request.httpBody = parameters.percentEncoded()

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {
                print("error", error ?? "Unknown error")
                return
            }

            guard (200 ... 299) ~= response.statusCode else {
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }

            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }

        task.resume()
    }
}
