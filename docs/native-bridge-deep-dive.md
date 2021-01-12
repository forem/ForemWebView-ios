# Native Bridge deep dive

The `ForemWebView` instance makes use of [WebKit's WKScriptMessageHandler](https://developer.apple.com/documentation/webkit/wkscriptmessagehandler) and this is what we commonly refer to as the Native Bridge. With a few clever techniques this allows our web context interact (bi-directionally) with the native implementation.

All these interactions are handled by the [WKScriptMessageHandler implementation](https://github.com/forem/ForemWebView-ios/blob/main/Sources/ForemWebView/ForemWebView+WKScriptMessageHandler.swift#L15).

## Podcast Player

The Podcast Player within [the Forem codebase](https://github.com/forem/forem/blob/master/app/assets/javascripts/initializers/initializePodcastPlayback.js) relies on the Native Bridge to communicate with the `ForemWebView` implementation in order to use native APIs for audio playback.

Messages are JSON encoded and sent both ways (JavaScript -> Swift and Swift -> JavaScript). These JSON messages all include an "action" and sometimes other optional values. This is how the JavaScript context is able to present a web UI while the actual audio player is an [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer).

You can see supported messages by the Swift context [here](https://github.com/forem/ForemWebView-ios/blob/main/Sources/ForemWebView/ForemMediaManager/ForemMediaManager.swift#L50) and the supported messages by the JavaScript context [here](https://github.com/forem/forem/blob/master/app/assets/javascripts/initializers/initializePodcastPlayback.js#L485).

## Video Player

The Video Player works in a very similar way, with JSON encoded messages exchanged between the native and the JavaScript contexts. This is a much more simplified process because the JavaScript context will send in a `play` message and the `ForemWebView` will create a fully native `AVPlayerViewController`.

It's the app's responsibility to implement the `ForemWebViewDelegate` and when a video player is initiated by the user the function `willStartNativeVideo(playerController: AVPlayerViewController)` will be called, giving you the opportunity to handle it. The most straightforward way of doing this is:

```swift
present(playerController, animated: true) {
    playerController.player?.play()
}
```

## Native Image Upload

The Swift context also implements an interface for Native Image Uploads (via Camera or Library picker). This interface allows for a button in the DOM to trigger the native flow and expect the result (uploaded image URL).

The JavaScript event triggered by the user's tap on an "Upload Image" button **requires** an `id` and supports an **optional** `ratio` for image cropping. The `id` represents the hidden input field used for receiving the events back from the Swift context. The `ratio` allows for cropping the image on a specific ratio if necessary. This is the sample code from `ArticleCoverImage.jsx` ([here](https://github.com/forem/forem/blob/cf0a85b3a47344db1d7653dea3e6e94dae58d8b5/app/javascript/article-form/components/ArticleCoverImage.jsx#L58) and [here](https://github.com/forem/forem/blob/cf0a85b3a47344db1d7653dea3e6e94dae58d8b5/app/javascript/article-form/components/ArticleCoverImage.jsx#L66)):

```js
initNativeImagePicker = (e) => {
  e.preventDefault();
  window.webkit.messageHandlers.imageUpload.postMessage({
    id: 'native-cover-image-upload-message',
    ratio: `${100.0 / 42.0}`,
  });
};
```

```js
handleNativeMessage = (e) => {
  const message = JSON.parse(e.target.value);

  switch (message.action) {
    case 'uploading':
      this.setState({ uploadingImage: true });
      this.clearUploadError();
      break;
    case 'error':
      this.setState({
        uploadingImage: false,
        uploadError: true,
        uploadErrorMessage: message.error,
      });
      break;
    case 'success':
      this.props.onMainImageUrlChange({ links: [message.link] });
      this.setState({ uploadingImage: false });
      break;
  }
};
```

You can also read through how the Swift code handles the `imageUpload` message [here](https://github.com/forem/ForemWebView-ios/blob/main/Sources/ForemWebView/ForemWebView+WKScriptMessageHandler.swift#L90).
