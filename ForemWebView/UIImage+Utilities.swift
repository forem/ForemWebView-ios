//
//  UIImage+Resize.swift
//  ForemWebView
//
//  Created by Fernando Valverde on 12/10/20.
//

import UIKit
import Alamofire

extension UIImage {
    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // This function will upload the UIImage to a Forem directly and will use a completion callback.
    // The first param in the callback will provide the uploaded image URL on success and the second
    // param will contain an error message if the upload was unsuccessful
    func uploadToForem(uploadUrl: String, token: String, completion: @escaping (String?, String?) -> Void) {
        guard let url = URL(string: uploadUrl), let uploadData = jpegData(compressionQuality: 0.9) else {
            completion(nil, nil)
            return
        }

        let uploadHeaders: HTTPHeaders = [
            HTTPHeader(name: "X-CSRF-Token", value: token),
            HTTPHeader(name: "Content-Type", value: "multipart/form-data")
        ]
        AF.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(uploadData,
                                     withName: "image",
                                     fileName: "m-\(UUID().uuidString).jpeg",
                                     mimeType: "image/jpeg")
            multipartFormData.append(Data(token.utf8), withName: "authenticity_token")
        }, to: url, method: .post, headers: uploadHeaders).responseJSON { (response) in

            guard let statusCode = response.response?.statusCode else {
                completion(nil, nil)
                return
            }

            if statusCode == 200, let result = response.value as? [String: [String]] {
                let links = result["links"] as [String]?
                completion(links?.first, nil)
            } else if let result = response.value as? [String: String] {
                completion(nil, result["error"])
            } else {
                completion(nil, nil)
            }
        }
    }
}
