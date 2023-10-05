//
//  EncryptionKeysInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 22/06/2023.
//

import SwiftUI
import AgoraRtcKit
import AVKit
#if os(iOS)
/// A protocol for views that require a custom camera capture device.
protocol HasCustomVideoInput: View, HasDocPath {
    init(channelId: String, customCamera: AVCaptureDevice, customMic: AVCaptureDevice)
}

extension CustomAudioVideoView: HasCustomVideoInput {}

/// A view that allows the user to choose a specific camera. It then navigates to a view that
/// accepts these inputs and connects to a channel with the appropriate camera device enabled.
///
/// The `CustomCameraInputView` takes a generic parameter `Content` that conforms to the `HasCustomVideoInput` protocol.
struct CustomCameraInputView<Content: HasCustomVideoInput>: View {
    /// The channel ID entered by the user.
    @State private var channelId: String = DocsAppConfig.shared.channel
    var availableCams = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
            .builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera
        ], mediaType: .video, position: .unspecified
    ).devices

    var availableMics = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInMicrophone],
        mediaType: .audio, position: .unspecified
    ).devices

    @State var selectedCamera: Int = 0
    @State var selectedMic: Int = 0

    /// The type of view to navigate to after the user inputs the channel ID and token URL.
    public var continueTo: Content.Type
    public var body: some View {
        if !availableCams.isEmpty {
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
                if !self.availableMics.isEmpty {
                    Picker("Choose Microphones", selection: $selectedMic) {
                        ForEach(Array(availableMics.enumerated()), id: \.offset) { idx, cam in
                            Text(cam.localizedName).tag(idx)
                        }
                    }.pickerStyle(MenuPickerStyle()).padding()
                }
                NavigationLink(destination: NavigationLazyView(continueTo.init(
                    channelId: channelId.trimmingCharacters(in: .whitespaces),
                    customCamera: availableCams[selectedCamera],
                    customMic: availableMics[selectedMic]
                ).navigationTitle(continueTo.docTitle).toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        GitHubButtonView(continueTo.docPath)
                    }
                    #endif
                }), label: {
                    Text(LocalizedStringKey("params-continue-button"))
                }).disabled(channelId.isEmpty)
                    .buttonStyle(.borderedProminent)
            }.onAppear {
                channelId = DocsAppConfig.shared.channel
            }
            .navigationTitle("Custom Camera Input")
        } else {
            Text("No cameras available.")
        }
    }
}

struct CustomCameraInputView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCameraInputView(continueTo: CustomAudioVideoView.self)
    }
}
#endif
