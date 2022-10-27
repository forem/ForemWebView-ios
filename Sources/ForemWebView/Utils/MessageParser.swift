//
//  MessageParser.swift
//
//
//  Created by Daniel Chick on 10/26/22.
//

import Foundation

public typealias Json = [String: Any]

public class MessageParser {
    public init () {}

    public func parse<T: Decodable>(jsonArray: [Json]) -> T? {
        guard let serializedInnerJSON = try? JSONSerialization.data(withJSONObject: jsonArray) else {
            return nil
        }
        
        return parseObject(serializedJson: serializedInnerJSON)
    }
    
    public func parse<T: Decodable>(json: Json) -> T? {
        guard let serializedInnerJSON = try? JSONSerialization.data(withJSONObject: json) else {
            return nil
        }

        return parseObject(serializedJson: serializedInnerJSON)
    }
    
    public func parse<T: Decodable>(json: Any) -> T? {
        guard let serializedInnerJSON = try? JSONSerialization.data(withJSONObject: json) else {
            return nil
        }

        return parseObject(serializedJson: serializedInnerJSON)
    }

    private func parseObject<T: Decodable> (serializedJson: Data) -> T? {
        do {
            return try JSONDecoder().decode(T.self, from: serializedJson)
        } catch {
            return nil
        }
    }
}
