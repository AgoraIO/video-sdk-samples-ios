//
//  CustomAudioVideoView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 24/05/2023.
//

import SwiftUI
import AVKit
import AgoraRtcKit

class CustomAudioVideoManager: AgoraManager {
    override init(appId: String, role: AgoraClientRole = .audience) {
        super.init(appId: appId, role: role)
        self.engine.setExternalVideoSource(
            true, useTexture: true, sourceType: .encodedVideoFrame
        )
    }
}

struct CustomAudioVideoView: View {
    /// The Agora SDK manager for call quality.
    @ObservedObject var agoraManager = AgoraManager(appId: AppKeys.agoraKey, role: .broadcaster)
    /// The channel ID to join.
    let channelId: String

    @State var captureDevice: AVCaptureDevice?

    var body: some View {
        ScrollView {
            VStack {
                ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                    AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                        .aspectRatio(contentMode: .fit).cornerRadius(10)
                }
            }.padding(20)
        }.onAppear {
            agoraManager.joinChannel(channelId, token: AppKeys.agoraToken)
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    init(channelId: String) {
        self.channelId = channelId
    }
}
