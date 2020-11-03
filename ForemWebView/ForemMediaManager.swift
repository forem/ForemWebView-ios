import UIKit
import AVKit
import MediaPlayer

class ForemMediaManager: NSObject {

    weak var webView: ForemWebView?

    var avPlayer: AVPlayer?
    var playerItem: AVPlayerItem?
    var currentStreamURL: String?
    weak var avPlayerController: AVPlayerViewController?
    var periodicTimeObserver: Any?

    var episodeName: String?
    var podcastName: String?
    var podcastRate: Float?
    var podcastVolume: Float?
    var podcastImageUrl: String?
    var podcastImageFetched: Bool = false
    
    lazy var bundleIcon: UIImage? = {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }()

    init(webView: ForemWebView) {
        self.webView = webView
    }

    func handleVideoMessage(_ message: [String: String]) {
        switch message["action"] {
        case "play":
            loadVideoPlayer(videoUrl: message["url"], seconds: message["seconds"])
        default: ()
        }
    }

    func handlePodcastMessage(_ message: [String: String]) {
        ensureAudioSessionIsActive()
        
        switch message["action"] {
        case "play":
            play(audioUrl: message["url"], at: message["seconds"])
        case "load":
            load(audioUrl: message["url"])
        case "seek":
            seek(to: message["seconds"])
        case "rate":
            podcastRate = Float(message["rate"] ?? "1")
            avPlayer?.rate = podcastRate ?? 1
        case "muted":
            avPlayer?.isMuted = (message["muted"] == "true")
        case "pause":
            avPlayer?.pause()
        case "terminate":
            avPlayer?.pause()
            clearPeriodicTimeObserver()
            UIApplication.shared.endReceivingRemoteControlEvents()
        case "volume":
            podcastVolume = Float(message["volume"] ?? "1")
            avPlayer?.rate = podcastVolume ?? 1
        case "metadata":
            loadMetadata(from: message)
        default: ()
        }
    }
    
    func clearPeriodicTimeObserver() {
        currentStreamURL = nil
        if let periodicTimeObserver = periodicTimeObserver {
            avPlayer?.removeTimeObserver(periodicTimeObserver)
        }
    }
    
    func ensureAudioSessionIsActive() {
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.isOtherAudioPlaying {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set audio session as Active")
            }
        }
    }
    
    // MARK: - Video Action Functions -
    
    func loadVideoPlayer(videoUrl: String?, seconds: String?) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            // TODO: Improve unsupported devices experience
            return
        }

        if currentStreamURL != videoUrl, let videoUrl = videoUrl, let url = NSURL(string: videoUrl) {
            clearPeriodicTimeObserver()
            self.webView?.closePodcastUI()
            currentStreamURL = videoUrl
            playerItem = AVPlayerItem.init(url: url as URL)
            avPlayer = AVPlayer.init(playerItem: playerItem)
            avPlayer?.volume = 1.0
            seek(to: seconds)
            avPlayer?.play()
            startVideoTimeObserver()
            
            var avPlayerControllerReference = self.avPlayerController
            if avPlayerControllerReference == nil {
                avPlayerControllerReference = AVPlayerViewController()
                avPlayerControllerReference?.allowsPictureInPicturePlayback = true
                avPlayerControllerReference?.delegate = self
                avPlayer?.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
                
                // Keep weak reference
                self.avPlayerController = avPlayerControllerReference
            } else {
                self.webView?.closePodcastUI()
            }
            
            avPlayerController?.player = avPlayer
            self.webView?.foremWebViewDelegate?.willStartNativeVideo(playerController: avPlayerControllerReference!)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" && avPlayer?.rate ?? 0 == 0 {
            webView?.sendBridgeMessage(type: "video", message: [ "action": "pause" ])
        }
    }

    // MARK: - Podcast Action Functions -

    private func play(audioUrl: String?, at seconds: String?) {
        var seconds = Double(seconds ?? "0")
        if currentStreamURL != audioUrl && audioUrl != nil {
            avPlayer?.pause()
            seconds = 0
            currentStreamURL = nil
            load(audioUrl: audioUrl)
        }

        guard avPlayer?.timeControlStatus != .playing else { return }
        avPlayer?.seek(to: CMTime(seconds: seconds ?? 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        avPlayer?.play()
        avPlayer?.rate = podcastRate ?? 1
        updateNowPlayingInfoCenter()
        setupNowPlayingInfoCenter()
    }

    private func seek(to seconds: String?) {
        guard let secondsStr = seconds, let seconds = Double(secondsStr) else { return }
        avPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    private func seekForward(_ sender: Any) {
        guard let duration  = avPlayer?.currentItem?.duration else { return }
        let playerCurrentTime = CMTimeGetSeconds(avPlayer!.currentTime())
        let newTime = playerCurrentTime + 15

        if newTime < (CMTimeGetSeconds(duration) - 15) {
            avPlayer!.seek(to: seekableTime(newTime), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }

    private func seekBackward(_ sender: Any) {
        let playerCurrentTime = CMTimeGetSeconds(avPlayer!.currentTime())
        var newTime = playerCurrentTime - 15
        if newTime < 0 {
            newTime = 0
        }
        avPlayer!.seek(to: seekableTime(newTime), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }

    private func seekableTime(_ seconds: Double) -> CMTime {
        return CMTimeMake(value: Int64(seconds * 1000 as Float64), timescale: 1000)
    }

    private func loadMetadata(from message: [String: String]) {
        episodeName = message["episodeName"]
        podcastName = message["podcastName"]
        if let newImageUrl = message["podcastImageUrl"], newImageUrl != podcastImageUrl {
            podcastImageUrl = newImageUrl
            podcastImageFetched = false
        }
    }

    private func updateTimeLabel(currentTime: Double, duration: Double) {
        guard currentTime > 0 && duration > 0 else {
            webView?.sendBridgeMessage(type: "podcast", message: ["action": "init"])
            return
        }

        let message = [
            "action": "tick",
            "duration": String(format: "%.4f", duration),
            "currentTime": String(format: "%.4f", currentTime)
        ]
        webView?.sendBridgeMessage(type: "podcast", message: message)
    }

    private func videoTick(currentTime: Double) {
        let message = [
            "action": "tick",
            "currentTime": String(format: "%.4f", currentTime)
        ]
        webView?.sendBridgeMessage(type: "podcast", message: message)
    }

    private func load(audioUrl: String?) {
        guard currentStreamURL != audioUrl && audioUrl != nil else { return }
        guard let url = NSURL(string: audioUrl!) else { return }
        clearPeriodicTimeObserver()
        currentStreamURL = audioUrl
        playerItem = AVPlayerItem.init(url: url as URL)
        avPlayer = AVPlayer.init(playerItem: playerItem)
        avPlayer?.volume = 1.0
        updateTimeLabel(currentTime: 0, duration: 0)

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        periodicTimeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] _ in
            guard let duration = self?.playerItem?.duration.seconds, !duration.isNaN else { return }
            let time: Double = self?.avPlayer?.currentTime().seconds ?? 0

            self?.updateTimeLabel(currentTime: time, duration: duration)
            self?.updateNowPlayingInfoCenter()
        }
    }

    private func startVideoTimeObserver() {
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        periodicTimeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] _ in
            guard self?.avPlayerController != nil else {
                self?.clearPeriodicTimeObserver()
                return
            }

            guard self?.avPlayer?.rate != 0 && self?.avPlayer?.error == nil else { return }
            guard let time: Double = self?.avPlayer?.currentTime().seconds else { return }
            let message = [
                "action": "tick",
                "currentTime": String(format: "%.4f", time)
            ]
            self?.webView?.sendBridgeMessage(type: "video", message: message)
        }
    }

    // MARK: - Locked Screen Functions -

    private func setupNowPlayingInfoCenter() {
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

    private func setupInfoCenterDefaultIcon() {
        if let appIcon = bundleIcon {
            let artwork = MPMediaItemArtwork(boundsSize: appIcon.size) { _ in return appIcon }
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
        }
    }

    private func updateNowPlayingInfoCenter() {
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
    
    private func urlFrom(urlString: String?) -> URL? {
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

    private func fetchRemoteArtwork() {
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

// MARK: - AVPlayerViewControllerDelegate -

extension ForemMediaManager: AVPlayerViewControllerDelegate {
    func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        self.webView?.foremWebViewDelegate?.willStartNativeVideo(playerController: playerViewController)
    }
}
