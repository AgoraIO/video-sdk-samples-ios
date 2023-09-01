# Secure channel encryption

Media stream encryption ensures that only the authorized users in a channel can see and hear each other. This ensures that potential eavesdroppers cannot access sensitive and private information shared in a channel. While not every use case requires media stream encryption, Video Calling provides built-in encryption methods that guarantee data confidentiality during transmission.

This page shows you how to integrate built-in media stream encryption into your app using Video SDK.

## Understand the code

For context on this sample, and a full explanation of the essential code snippets used in this project, read [Secure channel encryption](https://docs-beta.agora.io/en/video-calling/develop/media-stream-encryption)


## How to run this project

To see how to run this project, read the instructions in the main [README](../README.md) or [SDK quickstart](https://docs-beta.agora.io/en/video-calling/get-started/get-started-sdk).

The only things needed to add in this section is a secret encryption key and salt set on the `agoraEngine`, found here [MediaEncryptionManager](MediaEncryptionView.swift#L21-46). In this example the key and salt are hard coded in the application, however in a production app these should be received from your server.

