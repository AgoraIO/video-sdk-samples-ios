//
//  AppStoryViewProtocol.swift
//  Docs-Examples
//
//  Created by Max Cobb on 23/08/2023.
//

import SwiftUI

/// A protocol that defines the requirements for a SwiftUI view that displays Agora video feeds in a scrolling manner.
protocol AgoraStoryViewProtocol: View {
    /// The type of the manager that manages Agora communication.
    associatedtype ManagerType: AgoraManager

    /// The manager instance responsible for Agora communication.
    var agoraManager: ManagerType { get }
}

extension AgoraStoryViewProtocol {
    /// A computed property that returns a SwiftUI view containing a vertically scrolling stack of video feeds.
    public var basicScrollingVideos: some View {
        ScrollView { VStack { self.innerScrollingVideos }.padding(20) }
    }
    /// A computed property that returns a SwiftUI view containing video feeds of Agora participants.
    public var innerScrollingVideos: some View {
        // Show the video feeds for each participant.
        ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
            AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                .aspectRatio(contentMode: .fit).cornerRadius(10)
        }
    }
}

extension GettingStartedView: AgoraStoryViewProtocol {}
extension TokenAuthenticationView: AgoraStoryViewProtocol {}
extension CloudProxyView: AgoraStoryViewProtocol {}
extension StreamMediaView: AgoraStoryViewProtocol {}
extension ChannelRelayView: AgoraStoryViewProtocol {}
extension MediaEncryptionView: AgoraStoryViewProtocol {}
extension CallQualityView: AgoraStoryViewProtocol {}
extension ScreenShareAndVolumeView: AgoraStoryViewProtocol {}
extension CustomAudioVideoView: AgoraStoryViewProtocol {}
extension RawMediaProcessingView: AgoraStoryViewProtocol {}
extension GeofencingView: AgoraStoryViewProtocol {}
extension VirtualBackgroundView: AgoraStoryViewProtocol {}
