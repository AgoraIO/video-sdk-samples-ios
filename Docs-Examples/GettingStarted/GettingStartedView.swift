//
//  GettingStartedView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

/**
 A view that displays the video feeds of all participants in a channel.
 */
public struct GettingStartedView: View {
    @ObservedObject public var agoraManager = AgoraManager(appId: AppKeys.agoraKey, role: .broadcaster)
    /// The channel ID to join.
    public let channelId: String

    public var body: some View {
        // Show a scrollable view of video feeds for all participants.
        GettingStartedScrollView(
            users: agoraManager.allUsers, agoraKit: agoraManager.agoraKit
        ).onAppear {
            agoraManager.agoraKit.joinChannel(byToken: AppKeys.agoraToken, channelId: channelId, info: nil, uid: 0)
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    init(channelId: String) {
        self.channelId = channelId
    }
}

/**
 A scrollable view of video feeds for all participants in a channel.
 */
public struct GettingStartedScrollView: View {
    /// The set of user IDs for all participants in the channel.
    public var users: Set<UInt>
    /// A weak reference to the `AgoraRtcEngineKit` object for the session.
    public weak var agoraKit: AgoraRtcEngineKit?

    public var body: some View {
        if let agoraKit {
            ScrollView {
                VStack {
                    // Show the video feeds for each participant.
                    ForEach(Array(users), id: \.self) { uid in
                        AgoraVideoCanvasView(agoraKit: agoraKit, uid: uid)
                            .aspectRatio(contentMode: .fit).cornerRadius(10)
                    }
                }.padding(20)
            }
        }
    }
}

struct GettingStartedView_Previews: PreviewProvider {
    static var previews: some View {
        GettingStartedView(channelId: "test")
    }
}
