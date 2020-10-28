//
//  ForemUserData.swift
//  ForemWebView
//
//  Created by Fernando Valverde on 10/28/20.
//

import Foundation

public struct ForemUserData: Codable {
    enum CodingKeys: String, CodingKey {
        case userID = "id"
        case configBodyClass = "config_body_class"
    }
    public var userID: Int
    public var configBodyClass: String
}
