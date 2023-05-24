//
//  CallQualityView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

/**
 * A view that displays the video feeds of all participants in a channel, along with sliders for volume control.
 */
struct ScreenShareAndVolumeView: View {
    @State var volumeSetting: [UInt: Double] = [:]

    /// The Agora SDK manager for call quality.
    @ObservedObject var agoraManager = AgoraManager(appId: AppKeys.agoraKey, role: .broadcaster)
    /// The channel ID to join.
    let channelId: String

    var body: some View {
        ScrollView {
            VStack {
                ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                    AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                        .aspectRatio(contentMode: .fit).cornerRadius(10)
                        .overlay(alignment: .topLeading) {
                            VStack {
                                // If not the local user, add a slider for volume control.
                                if uid != agoraManager.localUserId {
                                    Spacer()
                                    Slider(value: volumeBinding(for: uid), in: 0...100, step: 10)
                                }
                            }.padding()
                        }
                }
            }.padding(20)
        }.onAppear { agoraManager.joinChannel(channelId, token: AppKeys.agoraToken) }
        .onDisappear { agoraManager.leaveChannel() }
    }

    private func volumeBinding(for key: UInt) -> Binding<Double> {
        Binding<Double>(
            get: { self.volumeSetting[key] ?? 100.0 },
            set: { newValue in
                self.volumeSetting[key] = newValue
                self.agoraManager.engine.adjustUserPlaybackSignalVolume(key, volume: Int32(newValue))
            }
        )
    }
    init(channelId: String) {
        self.channelId = channelId
    }
}
