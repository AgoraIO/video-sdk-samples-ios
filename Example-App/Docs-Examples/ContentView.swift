//
//  ContentView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 20/03/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Get Started") {
                    NavigationLink("SDK quickstart") {
                        ChannelInputView(continueTo: GettingStartedView.self)
                    }
                    NavigationLink("Secure authentication with tokens") {
                        TokenAuthInputView(continueTo: TokenAuthenticationView.self)
                    }
                }
                Section("Core functionality") {
                    NavigationLink("Connect through restricted networks with Cloud Proxy") {
                        ProxyInputView(continueTo: CloudProxyView.self)
                    }
                    NavigationLink("Stream media to a channel") {
                        MediaStreamInputView(continueTo: StreamMediaView.self)
                    }
                    NavigationLink("Secure channel encryption") {
                        EncryptionKeysInputView(continueTo: MediaEncryptionView.self)
                    }
                    NavigationLink("Call quality best practice") {
                        ChannelInputView(continueTo: CallQualityView.self)
                    }
                    NavigationLink("Screen share, volume control and mute") {
                        ChannelInputView(continueTo: ScreenShareAndVolumeView.self)
                    }
                    NavigationLink("Receive notifications about channel events") {}
                        .disabled(true)
                    NavigationLink("Custom video and audio sources") {
                        CustomCameraInputView(continueTo: CustomAudioVideoView.self)
                    }
                    NavigationLink("Raw video and audio processing") {
                        ChannelInputView(continueTo: RawMediaProcessingView
                            .self)
                    }
                    NavigationLink("Integrate an extension") {}.disabled(true)
                }
                Section("Integrate Features") {
                    NavigationLink("Audio and voice effects") {}.disabled(true)
                    NavigationLink("3D Spatial Audio") {}.disabled(true)
                    NavigationLink("AI Noise Suppression") {}.disabled(true)
                    NavigationLink("Geofencing") {
                        GeofenceInputView(continueTo: GeofencingView.self)
                    }
                    NavigationLink("Virtual Background") {}.disabled(true)
                }
            }.navigationTitle("Video SDK reference app").navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
