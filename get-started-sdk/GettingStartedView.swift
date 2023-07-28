//
//  GettingStartedView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

/// A view that displays the video feeds of all participants in a channel.
public struct GettingStartedView: View {
    @ObservedObject public var agoraManager = AgoraManager(appId: DocsAppConfig.shared.appId, role: .broadcaster)

    public var body: some View {
        // Show a scrollable view of video feeds for all participants.
        ScrollView {
            VStack {
                // Show the video feeds for each participant.
                ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                    AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                        .aspectRatio(contentMode: .fit).cornerRadius(10)
                }
            }.padding(20)
        }.onAppear {
            agoraManager.agoraEngine.joinChannel(
                byToken: DocsAppConfig.shared.rtcToken,
                channelId: DocsAppConfig.shared.channel,
                info: nil, uid: DocsAppConfig.shared.uid
            )
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    init(channelId: String) {
        DocsAppConfig.shared.channel = channelId
    }

    public static let docPath = getFolderName(from: #file)
    public static let docTitle = LocalizedStringKey("get-started-sdk-title")
}

struct GettingStartedView_Previews: PreviewProvider {
    static var previews: some View {
        GettingStartedView(channelId: "test")
    }
}
