#if os(iOS)

import MediaPlayer

extension ForemMediaManager {
    internal func setupNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.playCommand.addTarget { _ in
            let currentTime = String(self.avPlayer?.currentTime().seconds ?? 0)
            self.play(audioUrl: self.currentStreamURL, at: currentTime)
            self.updateNowPlayingInfoCenter()
            return .success
        }
        commandCenter.pauseCommand.addTarget { _ in
            self.avPlayer?.pause()
            return .success
        }
        commandCenter.skipForwardCommand.addTarget { _ in
            self.seekForward(15)
            return .success
        }
        commandCenter.skipBackwardCommand.addTarget { _ in
            self.seekBackward(15)
            return .success
        }
    }

    internal func setupInfoCenterDefaultIcon() {
        if let appIcon = bundleIcon {
            let artwork = MPMediaItemArtwork(boundsSize: appIcon.size) { _ in return appIcon }
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
        }
    }

    internal func updateNowPlayingInfoCenter() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = episodeName ?? "Podcast"
        info[MPMediaItemPropertyArtist] = podcastName ?? "DEV Community"
        info[MPMediaItemPropertyPlaybackDuration] = avPlayer?.currentItem?.duration.seconds ?? 0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = avPlayer?.currentTime().seconds ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        // Only attempt to fetch the image once and if unavailable setup default (App Icon)
        guard !podcastImageFetched else { return }
        podcastImageFetched = true
        fetchRemoteArtwork()
    }

    internal func urlFrom(urlString: String?) -> URL? {
        var resolvedURL: URL?
        if let urlString = urlString {
            resolvedURL = URL(string: urlString)
            // On local development the url might be relative and this check ensures an absolute URL
            if let baseHost = self.webView?.foremInstance?.domain, resolvedURL?.host == nil {
                resolvedURL = URL(string: "\(baseHost)\(urlString)")
            }
        }
        return resolvedURL
    }

    internal func fetchRemoteArtwork() {
        if let resolvedURL = urlFrom(urlString: podcastImageUrl) {
            let task = URLSession.shared.dataTask(with: resolvedURL) { data, response, error in
                guard error == nil, let data = data,
                    let mimeType = response?.mimeType, mimeType.contains("image/"),
                    let image = UIImage(data: data)
                else {
                    self.setupInfoCenterDefaultIcon()
                    return
                }
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
            }
            task.resume()
        } else {
            setupInfoCenterDefaultIcon()
        }
    }
}

#endif
