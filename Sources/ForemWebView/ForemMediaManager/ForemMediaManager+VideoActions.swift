#if os(iOS)

import AVKit

extension ForemMediaManager {
    internal func loadVideoPlayer(videoUrl: String?, seconds: String?) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            // Unsupported devices will use default web player features
            return
        }

        guard currentStreamURL != videoUrl else {
            // The user is interacting with the video player but it's same video
            if avPlayer?.rate == 0 {
                // The video player was paused -> Start playing again
                avPlayer?.play()
            }
            return
        }

        guard let videoUrl = videoUrl, let url = NSURL(string: videoUrl) else { return }

        // Video Player setup
        clearObservers()
        self.webView?.closePodcastUI()
        currentStreamURL = videoUrl
        playerItem = AVPlayerItem.init(url: url as URL)
        avPlayer = AVPlayer.init(playerItem: playerItem)
        avPlayer?.volume = 1.0
        seek(to: seconds)
        avPlayer?.play()
        startVideoTimeObserver()
        let avPlayerControllerReference = startVideoPlayerViewController()
        avPlayerControllerReference.player = avPlayer
        self.webView?.foremWebViewDelegate?.willStartNativeVideo(playerController: avPlayerControllerReference)
    }

    private func startVideoPlayerViewController() -> AVPlayerViewController {
        // Local variable is used to make sure we keep a reference to the avPlayerController
        var avPlayerControllerReference = self.avPlayerController
        if avPlayerControllerReference == nil {
            avPlayerControllerReference = AVPlayerViewController()
            avPlayerControllerReference?.allowsPictureInPicturePlayback = true
            avPlayerControllerReference?.entersFullScreenWhenPlaybackBegins = true
            videoPauseObserver = avPlayer?.observe(\.rate, options: .new) { (player, _) in
                if player.rate == 0 {
                    self.webView?.sendBridgeMessage(type: .video, message: [ "action": "pause" ])
                } else {
                    self.webView?.sendBridgeMessage(type: .video, message: [ "action": "play" ])
                }
            }

            // Update weak reference
            self.avPlayerController = avPlayerControllerReference
        } else {
            self.webView?.closePodcastUI()
        }
        return avPlayerControllerReference!
    }
}

#endif
