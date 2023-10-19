# Call quality best practice

Customer satisfaction for your Video Calling integrated app depends on the quality of video and audio it provides. Quality of audiovisual communication through your app is affected by the following factors:

- Bandwidth of network connection
- Stability of network connection
- Hardware quality
- Video and audio settings
- Echo
- Multiple users in a channel

This sample shows you how to use Video SDK features to account for these factors and ensure optimal audio and video 
quality in your app.

## Understand the code

For context on this sample, and a full explanation of the essential code snippets used in this project, read [Call quality best practice](https://docs.agora.io/en/video-calling/develop/ensure-channel-quality)

### Agora Logic

The business logic for the call quality guide can be found in [CallQualityManager](CallQualityView.swift#L12). You find code snippets for [starting a probe request](CallQualityView.swift#L16) and [seeing the response](CallQualityView.swift#L31-L36). You can also monitor [remote video stats](CallQualityView.swift#L44-L51), such as the received bitrate and packet loss rate, as well as [local video stats](CallQualityView.swift#L59-L69).

## How to run this project

To see how to run this project, read the instructions in the main [README](../README.md) or[SDK quickstart](https://docs.agora.io/en/interactive-live-streaming/get-started/get-started-sdk?platform=ios).
