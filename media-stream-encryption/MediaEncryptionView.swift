//
//  TokenAuthenticationView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 21/06/2023.
//

import SwiftUI
import AgoraRtcKit


class MediaEncryptionManager: AgoraManager {
    /// Create a new AgoraManager for media encryption, passing the key, salt and encryption mode.
    /// - Parameters:
    ///   - appId: App ID for connecting to Agora.
    ///   - role: Role for the local user
    ///   - encryptionKey: A 32-byte string for encryption.
    ///   - encryptionSalt: A 32-byte string in Base64 format for encryption.
    ///   - encryptionMode: Mode of encryption for Agora's encryption settings.
    init(
        appId: String, role: AgoraClientRole = .audience,
        encryptionKey: String, encryptionSalt: String, encryptionMode: AgoraEncryptionMode
    ) {
        super.init(appId: appId, role: role)
        self.enableEncryption(
            key: encryptionKey, salt: encryptionSalt, mode: encryptionMode
        )
    }

    // In a production environment, you retrieve the key and salt from
    // an authentication server. For this code example you generate locally.

    /// Enable the encryption of all incoming and outgoing videos.
    /// - Parameters:
    ///   - key: A 32-byte string for encryption.
    ///   - salt: A 32-byte string in Base64 format for encryption.
    ///   - mode: Mode of encryption for Agora's encryption settings.
    func enableEncryption(key: String, salt: String, mode: AgoraEncryptionMode) {
        // Convert the salt string in the Base64 format into bytes
        let encryptedSalt = Data(
            base64Encoded: salt, options: .ignoreUnknownCharacters
        )!

        // An object to specify encryption configuration.
        let config = AgoraEncryptionConfig()

        // Set secret key and salt.
        config.encryptionKey = key
        config.encryptionKdfSalt = encryptedSalt

        // Specify an encryption mode.
        config.encryptionMode = mode


        // Call the method to enable media encryption.
        if engine.enableEncryption(true, encryptionConfig: config) == 0 {
            print("Media encryption enabled.")
        }
    }
}

/**
 * A view that encrypts your channel connection through Agora.
 */
struct MediaEncryptionView: View {
    /// The Agora SDK manager.
    @ObservedObject var agoraManager: MediaEncryptionManager
    /// The channel ID to join.
    public let channelId: String

    /**
     * Initializes a new `MediaEncryptionView`.
     *
     * - Parameter channelId: The channel ID to join.
     */
    public init(channelId: String, encryptionKey: String, encryptionSalt: String, encryptionMode: AgoraEncryptionMode) {
        self.channelId = channelId
        agoraManager = MediaEncryptionManager(
            appId: AppKeys.agoraKey, role: .broadcaster, encryptionKey: encryptionKey, encryptionSalt: encryptionSalt, encryptionMode: encryptionMode
        )
    }

    var body: some View {
        ScrollView {
            VStack {
                ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                    AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                        .aspectRatio(contentMode: .fit).cornerRadius(10)
                }
            }.padding(20)
        }.onAppear { agoraManager.joinChannel(self.channelId)
        }.onDisappear { agoraManager.leaveChannel() }
    }
}

struct MediaEncryptionView_Previews: PreviewProvider {
    static var previews: some View {
        MediaEncryptionView(channelId: "test", encryptionKey: "", encryptionSalt: "", encryptionMode: .AES128ECB)
    }
}
