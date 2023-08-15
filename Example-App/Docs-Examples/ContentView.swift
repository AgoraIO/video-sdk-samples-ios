//
//  ContentView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 20/03/2023.
//

import SwiftUI

struct ContentView: View {
    @State var productChoice: RtcProducts = .rtc
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Product Selection
                Picker("Product", selection: $productChoice) {
                    ForEach(RtcProducts.allCases, id: \.rawValue) { option in
                        Text(option.description).tag(option)
                    }
                }.pickerStyle(MenuPickerStyle())
                // MARK: - Get Started Guides
                Section("Get Started") {
                    NavigationLink(GettingStartedView.docTitle) {
                        ChannelInputView(continueTo: GettingStartedView.self)
                    }
                    NavigationLink(TokenAuthenticationView.docTitle) {
                        TokenAuthInputView(continueTo: TokenAuthenticationView.self)
                    }
                }
                // MARK: - Core Functionality
                Section("Core functionality") {
                    NavigationLink(CloudProxyView.docTitle) {
                        ProxyInputView(continueTo: CloudProxyView.self)
                    }
                    if productChoice != .voice {
                        NavigationLink(StreamMediaView.docTitle) {
                            MediaStreamInputView(continueTo: StreamMediaView.self)
                        }
                    }
                    NavigationLink(MediaEncryptionView.docTitle) {
                        EncryptionKeysInputView(continueTo: MediaEncryptionView.self)
                    }
                    if productChoice == .ils {
                        NavigationLink(ChannelRelayView.docTitle) {
                            MultiChannelInputView(continueTo: ChannelRelayView.self)
                        }
                    }
                    NavigationLink(CallQualityView.docTitle) {
                        ChannelInputView(continueTo: CallQualityView.self)
                    }
                    NavigationLink(ScreenShareAndVolumeView.docTitle) {
                        ChannelInputView(continueTo: ScreenShareAndVolumeView.self)
                    }
                    NavigationLink("Receive notifications about channel events") {}
                        .disabled(true)
                    NavigationLink(CustomAudioVideoView.docTitle) {
                        CustomCameraInputView(continueTo: CustomAudioVideoView.self)
                    }
                    NavigationLink(RawMediaProcessingView.docTitle) {
                        ChannelInputView(continueTo: RawMediaProcessingView
                            .self)
                    }
                    NavigationLink("Integrate an extension") {}.disabled(true)
                }
                Section("Integrate Features") {
                    NavigationLink("Audio and voice effects") {}.disabled(true)
                    NavigationLink("3D Spatial Audio") {}.disabled(true)
                    NavigationLink("AI Noise Suppression") {}.disabled(true)
                    NavigationLink(GeofencingView.docTitle) {
                        GeofenceInputView(continueTo: GeofencingView.self)
                    }
                    NavigationLink("Virtual Background") {}.disabled(true)
                }
            }.navigationTitle(LocalizedStringKey("app_title")).navigationBarTitleDisplayMode(.inline)
        }.onAppear {
            self.productChoice = DocsAppConfig.shared.product
        }.onChange(of: self.productChoice) { newValue in
            DocsAppConfig.shared.product = newValue
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
