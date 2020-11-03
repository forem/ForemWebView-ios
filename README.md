# ForemWebView - iOS/macOS

This is the WKWebView customization that powers the Forem (coming soon) and [DEV](https://github.com/thepracticaldev/DEV-ios) mobile apps.

## Requirements

The Project supports iOS 13.x but features like Picture in Picture are only available for iPhones on iOS 14.x

## Installation

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate ForemWebView into your Xcode project using Carthage, specify it in your Cartfile:

```
github "ForemWebView ~> 0.1"
```

Then use [the recommended steps to include the framework in your project](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

#### Swift Package Manager & CocoaPods

Not yet supported. If interested in contributing, PRs for these are welcome!

## Usage

Initialize the ForemWebView from Storyboard, programmatically, or however you prefer to do so. This custom `WKWebView` implementation will handle it's own `WKNavigationDelegate`, so instead of implementing this logic yourself please rely on the provided `ForemWebViewDelegate` for callbacks.

#### Important notes:
- Using SwiftUI? [We would appreciate your feedback after trying out the framework](https://github.com/forem/ForemWebView-ios/issues/4).
- If your project requires more detailed access to `WKNavigationDelegate` callbacks [please add a feature request](https://github.com/forem/ForemWebView-ios/issues/new?template=feature_request.md).
- An example project is available in this repo showcasing a simple use-case.

#### The suggested approach to tap into the ForemWebView is:
1. Implement `ForemWebViewDelegate`
   - `func willStartNativeVideo(playerController: AVPlayerViewController)`
   - `func requestedExternalSite(url: URL)`
   - `func requestedMailto(url: URL)`
   - `func didStartNavigation()`
   - `func didFinishNavigation()`
1. Observe changes in the view's variables:
   - `userData` variable will be updated when a user logs in/out (`ForemUserData` or `nil` if unauthenticated)
   - `estimatedProgress`, `canGoBack`, `canGoForward`, `url`, and any other WKWebView variable for state updates
1. Make sure the first URL to be loaded corresponds to a valid Forem Instance
   - A `ForemWebViewError` will be raised if the first load was attempted on a invalid domain
   - `load(_ urlString: String)` provided for simplicity (see below)

#### The following helper functions/variables are available for use:

- `load(_ urlString: String)`
   - Helper method for simplicity: `webView.load("https://dev.to")`
- `isOAuthUrl(_ url: URL) -> Bool`
   - Responds to whether the url provided is one of the supported 3rd party redirect URLs in a OAuth protocol
   - Useful if implementing `WKNavigationDelegate` on your own (not recommended)
- `fetchUserData(completion: @escaping (ForemUserData?) -> Void)`
   - Async callback to request the `ForemUserData` struct from the current state of the DOM
   - Instead of polling with this function we recommend you register to observe the `userData` variable as you'll react to changes as they become available
- `userData`
   - Instance of `ForemUserData` when authenticated or `nil` otherwise
- `foremInstance`
   - `ForemInstanceMetadata` struct that represents the Forem Instance loaded. It will be `nil`until the first page load

## Native Podcast Player & Picture in Picture video

In order for your App to take advantage of these native features via the `ForemWebView` you'll need two things:
1. Make sure you enable `Audio, AirPlay, and Pciture in Picture` from the Background Mode capability in your Project's Target
1. Configure the AVAudioSession category to `.playback`, preferrably in your AppDelegate. 
   - A one liner that works for this is `try? AVAudioSession.sharedInstance().setCategory(.playback)` although handling the error will most likely prove helpful.
1. The `ForemWebView` will call `.setActive(true)` on the `AVAudioSession` shared instance when playback is initiated, so you don't need to make this call yourself.
1. The `ForemWebViewDelegate` will call `willStartNativeVideo` when the native video player is ready to start playing. It's your job to present this `AVPlayerViewController` (see Example in the project)

The podcast player will automatically take advantage of [Background audio](https://developer.apple.com/documentation/avfoundation/media_playback_and_selection/creating_a_basic_video_player_ios_and_tvos/enabling_background_audio) playback. If background playback is unavailable/unsupported the Podcast Player will still play the audio in your App in the foreground. However, when the App is sent to the background you'll be missing better Artwork, controls, and the playback will stop after some time.

## Contributing

Bug reports and feature requests are welcome in the [issue tracker](https://github.com/forem/ForemWebView-ios/issues).

For Pull Requests:
1. Fork and clone the project.
1. Create a branch, naming it either a feature or bug: git checkout -b feature/that-new-feature or bug/fixing-that-bug
1. Code and commit your changes. Bonus points if you write a [good commit message](https://chris.beams.io/posts/git-commit/): git commit -m 'Add some feature'
1. Push to the branch: git push origin feature/that-new-feature
1. Create a pull request for your branch 🎉

#### Project Tests

The tests are run using the Example app bundled in the project. You can use XCode to run the test suite or from a Terminal with the following command:

```bash
# Make sure the `destination` param is using an iOS/Simulator available in your local environment
set -o pipefail && xcodebuild -project ForemWebView.xcodeproj -scheme Example -sdk iphonesimulator -destination 'platform=iOS Simulator,OS=14.1,name=iPhone 12 Pro Max' test | xcpretty
```

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. Please see the [LICENSE](./LICENSE) file in our repository for the full text.

Like many open source projects, we require that contributors provide us with a Contributor License Agreement (CLA). By submitting code to the Forem project, you are granting us a right to use that code under the terms of the CLA.

Our version of the CLA was adapted from the Microsoft Contributor License Agreement, which they generously made available to the public domain under Creative Commons CC0 1.0 Universal.

Any questions, please refer to our [license FAQ](https://docs.forem.to/licensing/) doc or email yo@dev.to

<br/>

<p align="center">
  <img
    alt="sloan"
    width=250px
    src="https://thepracticaldev.s3.amazonaws.com/uploads/user/profile_image/31047/af153cd6-9994-4a68-83f4-8ddf3e13f0bf.jpg"
  />
  <br/>
  <strong>Happy Coding</strong> ❤️
</p>
