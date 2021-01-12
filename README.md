# ForemWebView - iOS

This is the WKWebView customization that powers the Forem (coming soon) and [DEV](https://github.com/thepracticaldev/DEV-ios) mobile apps.

## Requirements

The Project supports iOS 13.x but features like Picture in Picture are only available for iPhones on iOS 14.x

## Installation

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. Once you have your Swift package set up, adding ForemWebView as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```swift
dependencies: [
    .package(url: "https://github.com/forem/ForemWebView-ios.git", .upToNextMajor(from: "1.0.0"))
]
```

#### Carthage & CocoaPods

We've moved to supporting SPM and not Carthage or CocoaPods. If interested in contributing, PRs to support these are welcome!

## Usage

After importing the framework into your project you can initialize the ForemWebView like you would any other WKWebView (Storyboard, programmatically, etc). This custom `WKWebView` implementation will handle it's own `WKNavigationDelegate`, so instead of implementing this logic yourself please rely on the provided `ForemWebViewDelegate` for callbacks.

We have two *deep dive* documents:
- [ForemWebView deep dive](/docs/ForemWebView-deep-dive.md) is a walkthrough of the capabilities available when you're using the Framework in your project
- [Native Bridge deep dive](/docs/native-bridge-deep-dive.md) documents the native interface used to communicate between the Web (DOM + JS) and Swift contexts

#### Important notes:
- Using SwiftUI? [We would appreciate your feedback after trying out the framework](https://github.com/forem/ForemWebView-ios/issues/4).
- If your project requires more detailed access to `WKNavigationDelegate` callbacks [please add a feature request](https://github.com/forem/ForemWebView-ios/issues/new?template=feature_request.md).

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
set -o pipefail && xcodebuild -scheme ForemWebView -sdk iphonesimulator -destination 'platform=iOS Simulator,OS=14.2,name=iPhone 12 Pro Max' test | xcpretty
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
