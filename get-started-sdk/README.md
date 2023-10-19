# SDK quickstart
    
Video Calling enables one-to-one or small-group video chat connections with smooth, jitter-free streaming video. Agora’s Video SDK makes it easy to embed real-time video chat into web, mobile and native apps.

Thanks to Agora’s intelligent and global Software Defined Real-time Network (Agora SD-RTN™), you can rely on the highest available video and audio quality.

This page shows the minimum code you need to integrate high-quality, low-latency Video Calling features into your app using Video SDK.

## Understand the code

For context on this sample, and a full explanation of the essential code snippets used in this project, read [SDK quickstart](https://docs.agora.io/en/interactive-live-streaming/get-started/get-started-sdk?platform=ios).

### Agora Logic

Most of the business logic for the Agora quickstart guide can be found in [AgoraManager](../agora-manager/AgoraManager.swift). Here you will find code snippets for [initialising the engine](../agora-manager/AgoraManager.swift#L36-L44), monitoring when someone [joins the channel](../agora-manager/AgoraManager.swift#L155-L157) or [leaves the channel](../agora-manager/AgoraManager.swift#L167-L169).

Joining and leaving the channel can be found in [GettingStartedView](GettingStartedView.swift#L28-L36), in the onAppear and onDisappear views.

### Creating a Canvas

Creating a canvas for local or remote users in this project and example with Agora uses `AgoraRtcVideoCanvas`, and the SwiftUI class `UIViewRepresentable`. This can be found in [AgoraVideoCanvasView.swift](../agora-manager/AgoraVideoCanvasView.swift).

#### Without SwiftUI

To create a canvas without the wrapper or SwiftUI, you need an `AgoraRtcVideoCanvas`, a `UIView` and an `AgoraRtcEngineKit` instance.

Place the `UIView` in your app where you'd like it, set the `AgoraRtcVideoCanvas.view` to the `UIView`, and call the `AgoraRtcEngineKit` methods seen in [AgoraVideoCanvasView.swift#setUserId](../agora-manager/AgoraVideoCanvasView.swift#L63-L81), depending on whether it's a local camera feed, remote, another media source, or more.

## How to run this project

To see how to run this project, read the instructions in the main [README](../README.md) or [SDK quickstart](https://docs.agora.io/en/interactive-live-streaming/get-started/get-started-sdk?platform=ios).
