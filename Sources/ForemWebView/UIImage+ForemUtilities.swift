#if os(iOS)

import UIKit
import Alamofire

extension UIImage {

    // This function calculates the size of the image that will be uploaded (downsized if it exceeds the limit).
    // If either width or height are larger than the `sideLimit` the returned size will be downscaled proportionally.
    // Examples:
    // - (downsizeTarget = 1000): 3000x3000 -> 1000x1000, 2000x1000 -> 1000x500, ...
    // - (downsizeTarget = 500): 3000x3000 -> 500x500, 2000x1000 -> 500x250, ...
    func foremLimitedSize() -> CGSize {
        let sideLimit: CGFloat = 1000.0
        var ratio: CGFloat = 1.0

        if size.width > size.height && size.width > sideLimit {
            ratio = sideLimit / size.width
        } else if size.height > sideLimit {
            ratio = sideLimit / size.height
        }

        if ratio < 1.0 {
            return CGSize(width: floor(ratio * size.width), height: floor(ratio * size.height))
        }

        // The image is already appropriately sized
        return size
    }

    // This function will upload the UIImage to a Forem directly and will use a completion callback.
    // The first param in the callback will provide the uploaded image URL on success and the second
    // param will contain an error message if the upload was unsuccessful
    func uploadTo(url: String, token: String, completion: @escaping (String?, String?) -> Void) {
        guard let url = URL(string: url), let uploadData = jpegData(compressionQuality: 0.9) else {
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
            } else if let error = response.error {
                completion(nil, error.localizedDescription)
            } else {
                completion(nil, nil)
            }
        }
    }
}

#endif
