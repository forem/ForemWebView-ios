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

## Features / Public interface

Initialize the ForemWebView and treat it as if it were just another WKWebView. An example project is available in this repo.

```swift
webView.navigationDelegate = self
webView.foremWebViewDelegate = self

// Our custom `load(_ urlString: String)` function
webView.load("https://dev.to")

// Once a page is loaded via `.load(...)` the `baseHost` variable
// will remain available for future use
print(webView.baseHost)
```

You're in charge of the `navigationPolicy`, but we provide a few helper methods like `isOAuthUrl` which will help make these decisions. The current interface supports:

- `load(_ urlString: String)` -> Recommended interface for programmatically loading a URL in the webView
- `isOAuthUrl(_ url: URL) -> Bool` -> Responds to whether the url provided is one of the supported 3rd party redirect URLs in a OAuth protocol
- `fetchUserStatus(completion: @escaping (String?) -> Void)` -> Async callback to request the user status (i.e. `logged-in`)
- `fetchUserData(completion: @escaping (ForemUserData?) -> Void)` -> Async callback to request the `ForemUserData` struct

## Picture in Picture video

In order for your app to support PiP you'll need to configure two more things:
1. Add the `Audio, Airplay, and Picture in Picture` Capability in your Project's Target
1. Configure the AVAudioSession category to `.playback`, preferrably in your AppDelegate. A one liner that works for this is `try? AVAudioSession.sharedInstance().setCategory(.playback)`

## Contributing

Bug reports and feature requests are welcome in the [issue tracker](https://github.com/forem/ForemWebView-ios/issues).

For Pull Requests:
1. Fork and clone the project.
1. Create a branch, naming it either a feature or bug: git checkout -b feature/that-new-feature or bug/fixing-that-bug
1. Code and commit your changes. Bonus points if you write a [good commit message](https://chris.beams.io/posts/git-commit/): git commit -m 'Add some feature'
1. Push to the branch: git push origin feature/that-new-feature
1. Create a pull request for your branch 🎉

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
