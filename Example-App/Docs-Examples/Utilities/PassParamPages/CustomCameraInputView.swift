//
//  EncryptionKeysInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 22/06/2023.
//

import SwiftUI
import AgoraRtcKit
import AVKit

/**
 A protocol for views that require a custom camera capture device.
 */
public protocol HasCustomVideoInput: View {
    /// The channel ID to join.
    var channelId: String { get }
    init(channelId: String, customCamera: AVCaptureDevice?)
}

extension CustomAudioVideoView: HasCustomVideoInput {}

/**
 A view that allows the user to choose a specific camera. It then navigates to a view that accepts these inputs and connects to a channel with the appropriate camera device enabled.

 The `CustomCameraInputView` takes a generic parameter `Content` that conforms to the `HasCustomVideoInput` protocol.
 */
public struct CustomCameraInputView<Content: HasCustomVideoInput>: View {
    /// The channel ID entered by the user.
    @State private var channelId: String = DocsAppConfig.shared.channel
    var availableCams = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera], mediaType: .video, position: .back
    ).devices

    @State var selectedCamera: Int = 0


    /// The type of view to navigate to after the user inputs the channel ID and token URL.
    public var continueTo: Content.Type
    public var body: some View {
        VStack {
            TextField("Enter channel id", text: $channelId)
                .textFieldStyle(.roundedBorder).padding([.horizontal, .top])
            if !self.availableCams.isEmpty {
                Picker("Choose Camera", selection: $selectedCamera) {
                    ForEach(Array(availableCams.enumerated()), id: \.offset) { idx, cam in
                        Text(cam.localizedName).tag(idx)
                    }
                }.pickerStyle(MenuPickerStyle()).padding()
            }
            NavigationLink(destination: continueTo.init(
                channelId: channelId.trimmingCharacters(in: .whitespaces),
                customCamera: availableCams.count > selectedCamera ? availableCams[selectedCamera] : nil
            ), label: {
                Text("Join Channel")
            }).disabled(channelId.isEmpty)
                .buttonStyle(.borderedProminent)
        }
    }
}


struct CustomCameraInputView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCameraInputView(continueTo: CustomAudioVideoView.self)
    }
}
