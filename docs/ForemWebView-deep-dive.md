# ForemWebView deep dive

This document provides an in-depth walkthrough of the features available to you after adding and initializing a `ForemWebView` instance in your project.

It's important to know this is a custom implementation of `WKWebView` and you **should not** implement your own `WKNavigationDelegate` logic. Please rely on the provided `ForemWebViewDelegate` for callbacks.

## Navigation and Lifecycle

1. Load a Forem instance URL
   - After the first load of a valid Forem instance the variable `foremInstance` will be populated with corresponding metadata
   - As soon as the `foremInstance` metadata is populated any attempts to navigate (programmatically or by the user) outside the Forem instance will be restricted by the `ForemWebView` itself
   - A simple way to get started would be to call `.load("https://dev.to")` on your `ForemWebView` instance
1. Implement `ForemWebViewDelegate` for callbacks
1. Observe changes in the view's **variables**:
   - `userData` will be updated when a user logs in/out (`ForemUserData` or `nil` if unauthenticated)
   - `estimatedProgress`, `canGoBack`, `canGoForward`, `url`, and any other WKWebView variable for state updates

## Available helper functions/variables

- `load(_ urlString: String)`
   - Helper method for simplicity: `webView.load("https://dev.to")`
- `userData`
   - Instance of `ForemUserData` when authenticated or `nil` otherwise
- `foremInstance`
  - `ForemInstanceMetadata` struct that represents the Forem Instance loaded. It will be `nil`until the first page load
- `fetchUserData(completion: @escaping (ForemUserData?) -> Void)`
  - Async callback to request the `ForemUserData` struct from the current state of the DOM
  - Instead of polling with this function we recommend you register to observe the `userData` variable as you'll react to changes when they become available
- `fetchUserData(completion: @escaping (ForemUserData?) -> Void)`

Extension to `URL`

- `.isOAuthUrl -> Bool`
   - Responds to whether the url is one of the supported 3rd party redirect URLs in a OAuth protocol
   - Useful if implementing `WKNavigationDelegate` on your own (not recommended)

## Native Podcast Player & Picture in Picture video

In order for your App to take advantage of these native features via the `ForemWebView` you'll need to configure a few things:
1. Make sure you enable `Audio, AirPlay, and Pciture in Picture` from the Background Mode capability in your Project's Target
1. Configure the AVAudioSession category to `.playback`, preferrably in your AppDelegate.
   - A one liner that works for this is `try? AVAudioSession.sharedInstance().setCategory(.playback)` although handling the error will most likely prove helpful.
1. The `ForemWebView` will call `.setActive(true)` on the `AVAudioSession` shared instance when playback is initiated, so you don't need to make this call yourself.
1. The `ForemWebViewDelegate` method `willStartNativeVideo` will be called when the native video player is ready to start playing. It's your responsibility to present this `AVPlayerViewController`

The podcast player will automatically take advantage of [Background audio](https://developer.apple.com/documentation/avfoundation/media_playback_and_selection/creating_a_basic_video_player_ios_and_tvos/enabling_background_audio) playback. If background playback is unavailable/unsupported the Podcast Player will still play the audio in your App in the foreground. However, when the App is sent to the background you'll be missing better Artwork, controls, and the playback will stop after some time.
