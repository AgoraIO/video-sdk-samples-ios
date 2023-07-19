# Config

This README provides information about the configuration file [`config.json`](config.json) used in the project. The file contains the following structure:

```json
{
    "uid": 0,
    "channel": "test",
    "appId": "",
    "rtcToken": "",
    "tokenUrl": "",
    "signalingToken": "",
    "encryptionMode": 7,
    "salt": "",
    "cipherKey": "",
    "proxyUrl": "",
    "proxyType": "none",
    "screenShareId": 10001
}
```

## DocsAppConfig Struct

The `DocsAppConfig` struct represents the configuration for the application and provides a shared instance of the configuration data. It conforms to the `Codable` protocol for easy serialization and deserialization of JSON data.

### Properties

- `uid`: The user ID associated with the application.
- `appId`: The unique ID for the application obtained from https://console.agora.io.
- `channel`: The pre-filled text for the channel to join.
- `rtcToken`: The RTC (Real-Time Communication) token generated for authentication.
- `signalingToken`: The signaling token generated for authentication.
- `encryptionMode`: The mode for encryption, ranging from 1 to 8.
- `salt`: The salt used for RTC encryption.
- `cipherKey`: The encryption key used for RTC encryption.
- `proxyUrl`: The URL of the proxy server to be used.
- `proxyType`: The type of the proxy server, which can be "none", "tcp", or "udp".
- `tokenUrl`: The URL for the token generator.
- `screenShareId`: The ID used for screen shares by default. Accessing the Configuration To access the configuration, use the shared property of the DocsAppConfig struct.

The configuration data is loaded from the config.json file located in the project bundle.

```swift
let config = DocsAppConfig.shared

// Accessing the configuration properties
let uid = config.uid
let appId = config.appId
let channel = config.channel
// ... and so on
```

## Note on `rtcToken`

If the `rtcToken` property in the configuration is an empty string, it will be assigned a value of `nil` for convenience.

Please ensure that the [`config.json`](config.json) file is correctly populated with the required values before running the application.