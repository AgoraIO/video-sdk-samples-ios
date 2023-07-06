#  Secure authentication with tokens

Authentication is the act of validating the identity of each user before they access a system. Agora uses digital tokens to authenticate users and their privileges before they access Agora SD-RTN™ to join Video Calling. Each token is valid for a limited period and works only for a specific channel. For example, you cannot use the token generated for a channel called AgoraChannel to join the AppTest channel.

This page shows you how to quickly set up an authentication token server, retrieve a token from the server, and use it to connect securely to a specific Video Calling channel. You use this server for development purposes. To see how to develop your own token generator and integrate it into your production IAM system, read Token generators.

## Topics

### Token Logic

With your token server set up using the example found [here](https://github.com/AgoraIO-Community/agora-token-service), you'll need to take note of your token server to pass into a network request.

There's a network request in swift written out in [TokenAuthenitcationView](TokenAuthenitcationView.swift#L25), in a function that returns the token as a String.

### Agora Logic

Once you have your token, join the channel using the Agora SDK, passing the token, as can be seen [here](TokenAuthenitcationView.swift#L100).

## Full Documentation

[Agora's full token authentication guide](https://docs.agora.io/en/interactive-live-streaming/develop/authentication-workflow?platform=ios)

