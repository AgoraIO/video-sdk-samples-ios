#  Secure authentication with tokens

Authentication is the act of validating the identity of each user before they access a system. Agora uses digital tokens to authenticate users and their privileges before they access Agora SD-RTN™ to join Video Calling. Each token is valid for a limited period and works only for a specific channel. For example, you cannot use the token generated for a channel called AgoraChannel to join the AppTest channel.

This page shows you how to quickly set up an authentication token server, retrieve a token from the server, and use it to connect securely to a specific Video Calling channel. You use this server for development purposes. To see how to develop your own token generator and integrate it into your production IAM system, read Token generators.

## Understand the code


For context on this sample, and a full explanation of the essential code snippets used in this project, read [Secure authentication with tokens](https://docs-beta.agora.io/en/video-calling/get-started/authentication-workflow).

### Token Logic

With your token server set up using the example found [here](https://github.com/AgoraIO-Community/agora-token-service), you'll need to take note of your token server to pass into a network request.

There's a network request in swift written out in [TokenAuthenitcationView](TokenAuthenticationView.swift#L23-L37), in a function that returns the token as a String.

### Agora Logic

Once you have the token, join the channel using the Agora SDK with the token, as can be seen in [here](TokenAuthenticationView.swift#L106-L110), and [here in the AgoraManager](../agora-manager/AgoraManager.swift#L80-L83).

## How to run this project

To see how to run this project, read the instructions in the main [README](../../README.md) or [SDK quickstart](https://docs-beta.agora.io/en/video-calling/get-started/get-started-sdk).

