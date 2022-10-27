//
//  Podcast.swift
//  
//
//  Created by Daniel Chick on 10/26/22.
//

import Foundation

public final class Podcast: Codable {
    let action: PodcastAction
    let url: String?
    let seconds: String?
    let rate: Float?
    let muted: Bool?
    let volume: Float?
}

public enum PodcastAction: String, Codable {
    case play
    case load
    case seek
    case rate
    case muted
    case pause
    case terminate
    case volume
    case metadata
    
}
