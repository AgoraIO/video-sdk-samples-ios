//
//  CallQualityView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import ReplayKit
import AgoraRtcKit

/**
 * A view that displays the video feeds of all participants in a channel, along with sliders for volume control.
 * This view displays a ``RPSystemBroadcastPickerWrapper`` at the bottom, which is a light wrapper
 * of the broadcast picker from ReplayKit.
 */
struct ScreenShareAndVolumeView: View {
    @State var volumeSetting: [UInt: Double] = [:]

    /// The Agora SDK manager for call quality.
    @ObservedObject var agoraManager = AgoraManager(appId: DocsAppConfig.shared.appId, role: .broadcaster)
    /// The channel ID to join.
    let channelId: String

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                        AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                            .aspectRatio(contentMode: .fit).cornerRadius(10)
                            .overlay(alignment: .topLeading) {
                                VStack {
                                    Spacer()
                                    Slider(value: volumeBinding(for: uid), in: 0...100, step: 10)
                                }.padding()
                            }
                    }
                }.padding(20)
            }.onAppear {
                agoraManager.joinChannel(channelId, token: DocsAppConfig.shared.rtcToken)

                // suiteName is the App Group assigned to the main app and the broadcast extension.
                // This sets the channel name so the broadcast extension can join the same channel.
                let userDefaults = UserDefaults(suiteName: "group.uk.rocketar.Docs-Examples")
                userDefaults?.set(self.channelId, forKey: "channel")
            }.onDisappear { agoraManager.leaveChannel() }
            // screenSharer is the name of the broadcast extension in this app's case.
            // If we can find the extension, display the broadcast picker.
            if let url = Bundle.main.url(forResource: "screenSharer", withExtension: "appex", subdirectory: "PlugIns"),
               let bundle = Bundle(url: url) {
                Group {
                    RPSystemBroadcastPickerWrapper(preferredExtension: bundle.bundleIdentifier)
                }.frame(height: 44).padding().background(.tertiary)
            }
        }
    }

    private func volumeBinding(for key: UInt) -> Binding<Double> {
        Binding<Double>(
            get: { self.volumeSetting[key] ?? 100.0 },
            set: { newValue in
                self.volumeSetting[key] = newValue
                if key == agoraManager.localUserId {
                    self.agoraManager.engine.adjustRecordingSignalVolume(Int(newValue))
                } else {
                    self.agoraManager.engine.adjustUserPlaybackSignalVolume(key, volume: Int32(newValue))
                }
            }
        )
    }
    init(channelId: String) {
        self.channelId = channelId
    }
}
