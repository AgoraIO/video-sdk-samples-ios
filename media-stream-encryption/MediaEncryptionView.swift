//
//  MediaEncryptionView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 21/06/2023.
//

import SwiftUI
import AgoraRtcKit

fileprivate extension AgoraManager {
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
        )

        // An object to specify encryption configuration.
        let config = AgoraEncryptionConfig()

        // Set secret key and salt.
        config.encryptionKey = key
        config.encryptionKdfSalt = encryptedSalt

        // Specify an encryption mode.
        config.encryptionMode = mode

        // Call the method to enable media encryption.
        if agoraEngine.enableEncryption(true, encryptionConfig: config) == 0 {
            label = "Media encryption enabled."
        } else {
            label = "Media encryption failed."
        }
    }
}

/// A view that encrypts your channel connection through Agora.
struct MediaEncryptionView: View {
    /// The Agora SDK manager.
    @ObservedObject var agoraManager = AgoraManager(
        appId: DocsAppConfig.shared.appId, role: .broadcaster
    )

    var body: some View {
        ZStack {
            self.basicScrollingVideos
            ToastView(message: $agoraManager.label)
        }.onAppear {
            agoraManager.enableEncryption(
                key: self.encryptionKey, salt: self.encryptionSalt,
                mode: self.encryptionMode
            )
            await agoraManager.joinChannel(DocsAppConfig.shared.channel)
        }.onDisappear { agoraManager.leaveChannel() }
    }
    let encryptionKey: String
    let encryptionSalt: String
    let encryptionMode: AgoraEncryptionMode

    /// Initializes a new `MediaEncryptionView`.
    ///
    /// - Parameters:
    ///   - channelId: The channel ID to join.
    ///   - encryptionKey: A 32-byte string for encryption.
    ///   - encryptionSalt: A 32-byte string in Base64 format for encryption.
    ///   - encryptionMode: Mode of encryption for Agora's encryption settings.
    public init(
        channelId: String, encryptionKey: String,
        encryptionSalt: String, encryptionMode: AgoraEncryptionMode
    ) {
        DocsAppConfig.shared.channel = channelId
        self.encryptionKey = encryptionKey
        self.encryptionSalt = encryptionSalt
        self.encryptionMode = encryptionMode
    }
    static let docPath = getFolderName(from: #file)
    static let docTitle = LocalizedStringKey("media-stream-encryption-title")
}

struct MediaEncryptionView_Previews: PreviewProvider {
    static var previews: some View {
        MediaEncryptionView(channelId: "test", encryptionKey: "", encryptionSalt: "", encryptionMode: .AES128ECB)
    }
}
