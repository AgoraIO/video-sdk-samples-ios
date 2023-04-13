# Secure authentication with tokens

Authentication is the act of validating the identity of each user before they access a system. Agora uses digital tokens to authenticate users and their privileges before they access Agora SD-RTN™ to join Video Calling. Each token is valid for a limited period and works only for a specific channel. For example, you cannot use the token generated for a channel called AgoraChannel to join the AppTest channel.

This page shows you how to quickly set up an authentication token server, retrieve a token from the server, and use it to connect securely to a specific Video Calling channel. You use this server for development purposes. To see how to develop your own token generator and integrate it into your production IAM system, read Token generators.

## Understand the tech

An authentication token is a dynamic key that is valid for a maximum of 24 hours. On request, a token server returns an authentication token that is valid to join a specific channel.

When users attempt to connect to an Agora channel from your app, your app retrieves a token from the token server in your security infrastructure. Your app then sends this token to Agora SD-RTN™ for authentication. Agora SD-RTN™ validates the token and reads the user and project information stored in the token. A token contains the following information:

ETC as current doc. 