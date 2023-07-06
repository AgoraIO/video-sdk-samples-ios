//
//  EncryptionKeysInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 22/06/2023.
//

import SwiftUI
import AgoraRtcKit

/**
 A protocol for views that require an encryption key, salt and mode.
 */
public protocol HasEncryptionInput: View {
    /// The channel ID to join.
    var channelId: String { get }
    init(channelId: String, encryptionKey: String, encryptionSalt: String, encryptionMode: AgoraEncryptionMode)
}

extension MediaEncryptionView: HasEncryptionInput {}

/// A view that allows the user to input a channel ID encyprtion key, salt and encryption mode.
///
/// The view then navigates to a view that accepts these inputs and
/// connects to a channel with the appropriate encryption enabled.
/// The `EncryptionKeysInputView` takes a generic parameter `Content`
/// which conforms to the `HasEncryptionInput` protocol.
public struct EncryptionKeysInputView<Content: HasEncryptionInput>: View {
    /// The channel ID entered by the user.
    @State private var channelId: String = DocsAppConfig.shared.channel
    /// A 32-byte string for encryption.
    @State private var encryptionKey: String = DocsAppConfig.shared.cipherKey
    /// A 32-byte string in Base64 format for encryption.
    @State private var encryptionSalt: String = DocsAppConfig.shared.salt
    /// Type of encryption to enable
    @State private var encryptionType: AgoraEncryptionMode = .init(
        rawValue: DocsAppConfig.shared.encryptionMode
    ) ?? .AES128GCM2

    /// The type of view to navigate to after the user inputs the channel ID and token URL.
    public var continueTo: Content.Type
    public var body: some View {
        VStack {
            TextField("Enter channel id", text: $channelId)
                .textFieldStyle(.roundedBorder).padding([.horizontal, .top])
            TextField("Enter Encryption Key", text: $encryptionKey).autocorrectionDisabled()
                .textFieldStyle(.roundedBorder).padding([.horizontal])
            TextField("Enter Encryption Salt", text: $encryptionSalt).autocorrectionDisabled()
                .textFieldStyle(.roundedBorder).padding([.horizontal])
            Picker("Choose Encryption Type", selection: $encryptionType) {
                ForEach(AgoraEncryptionMode.allCases) { option in
                    Text(option.description).tag(option)
                }
            }.pickerStyle(MenuPickerStyle()).textFieldStyle(.roundedBorder).padding()
            NavigationLink {
                continueTo.init(
                    channelId: channelId.trimmingCharacters(in: .whitespaces),
                    encryptionKey: encryptionKey.trimmingCharacters(in: .whitespaces),
                    encryptionSalt: encryptionSalt.trimmingCharacters(in: .whitespaces),
                    encryptionMode: self.encryptionType
                )
            } label: {
                Text("Join Channel")
            }.buttonStyle(.borderedProminent)
                .disabled(channelId.isEmpty || encryptionKey.isEmpty || encryptionSalt.isEmpty)
        }
    }
}

extension AgoraEncryptionMode: Identifiable, CaseIterable {
    public static var allCases: [AgoraEncryptionMode] = [
        /** 128-bit AES encryption, XTS mode. */
        .AES128XTS,
        /** 128-bit AES encryption, ECB mode. */
        .AES128ECB,
        /** 256-bit AES encryption, XTS mode. */
        .AES256XTS,
        /** 128-bit SM4 encryption, ECB mode. */
        .SM4128ECB,
        /** 128-bit AES encryption, GCM mode. */
        .AES128GCM,
        /** 256-bit AES encryption, GCM mode. */
        .AES256GCM,
        /** 128-bit AES encryption, GCM mode, with KDF salt */
        .AES128GCM2,
        /** 256-bit AES encryption, GCM mode, with KDF salt */
        .AES256GCM2
    ]
    var description: String {
        switch self {
        case .AES128XTS: return "128-bit AES encryption, XTS mode."
        case .AES128ECB: return "128-bit AES encryption, ECB mode."
        case .AES256XTS: return "256-bit AES encryption, XTS mode."
        case .SM4128ECB: return "128-bit SM4 encryption, ECB mode."
        case .AES128GCM: return "128-bit AES encryption, GCM mode."
        case .AES256GCM: return "256-bit AES encryption, GCM mode."
        case .AES128GCM2: return "128-bit AES encryption, GCM mode, with KDF salt"
        case .AES256GCM2: return "256-bit AES encryption, GCM mode, with KDF salt"
        default: return "Unknown"
        }
    }
    public var id: Int { rawValue }

}

struct EncryptionKeysInputView_Previews: PreviewProvider {
    static var previews: some View {
        EncryptionKeysInputView(continueTo: MediaEncryptionView.self)
    }
}
