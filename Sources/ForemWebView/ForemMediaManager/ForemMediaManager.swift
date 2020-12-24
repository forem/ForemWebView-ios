#if os(iOS)

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
    var videoPauseObserver: Any?

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

    // MARK: - Message handler functions

    internal func handleVideoMessage(_ message: [String: String]) {
        switch message["action"] {
        case "play":
            loadVideoPlayer(videoUrl: message["url"], seconds: message["seconds"])
        default: ()
        }
    }

    internal func handlePodcastMessage(_ message: [String: String]) {
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
            clearObservers()
            UIApplication.shared.endReceivingRemoteControlEvents()
        case "volume":
            podcastVolume = Float(message["volume"] ?? "1")
            avPlayer?.rate = podcastVolume ?? 1
        case "metadata":
            loadMetadata(from: message)
        default: ()
        }
    }

    // MARK: - Helper functions

    internal func clearObservers() {
        currentStreamURL = nil
        periodicTimeObserver = nil
        videoPauseObserver = nil
    }

    internal func ensureAudioSessionIsActive() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session as Active")
        }
    }
}

#endif
