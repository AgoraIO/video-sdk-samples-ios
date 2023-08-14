//
//  GettingStartedView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

public class RelayManager: AgoraManager {
    var mediaRelaying: Bool? = false
    var sourceChannel: String
    var destChannel: String
    // Can be any number, the range is arbitrary
    var destUid: UInt = .random(in: 1000...5000)
    init(sourceChannel: String, destChannel: String) {
        self.sourceChannel = sourceChannel
        self.destChannel = destChannel
        super.init(appId: DocsAppConfig.shared.appId, role: .broadcaster)
    }
    func channelRelayBtnClicked() async {
        guard let mediaRelaying else { return }
        self.mediaRelaying = nil
        if mediaRelaying {
            agoraEngine.stopChannelMediaRelay()
        } else {
            var sourceChannelToken: String? = nil
            if !DocsAppConfig.shared.tokenUrl.isEmpty {
                sourceChannelToken = try? await self.fetchToken(
                    from: DocsAppConfig.shared.tokenUrl, channel: sourceChannel, role: .broadcaster
                )
            }
            // Configure the source channel information.
            let srcChannelInfo = AgoraChannelMediaRelayInfo(token: sourceChannelToken)
            srcChannelInfo.channelName = sourceChannel
            srcChannelInfo.uid = 0
            let mediaRelayConfiguration = AgoraChannelMediaRelayConfiguration()
            mediaRelayConfiguration.sourceInfo = srcChannelInfo

            var destChannelToken: String? = nil
            if !DocsAppConfig.shared.tokenUrl.isEmpty {
                destChannelToken = try? await self.fetchToken(
                    from: DocsAppConfig.shared.tokenUrl, channel: destChannel, role: .broadcaster
                )
            }

            // Configure the destination channel information.
            let destChannelInfo = AgoraChannelMediaRelayInfo(token: destChannelToken)
            destChannelInfo.channelName = destChannel
            destChannelInfo.uid = destUid
            mediaRelayConfiguration.setDestinationInfo(destChannelInfo, forChannelName: destChannel)

            // Start relaying media streams across channels
            agoraEngine.startOrUpdateChannelMediaRelay(mediaRelayConfiguration)
        }
    }

    @Published var label: String?

    func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        channelMediaRelayStateDidChange state: AgoraChannelMediaRelayState,
        error: AgoraChannelMediaRelayError
    ) {
        var outputLabel: String
        switch state {
        case .connecting:
            outputLabel = "Channel media relay is connecting."
        case .running:
            mediaRelaying = true
            outputLabel = "Channel media relay is running."
        case .failure:
            mediaRelaying = false
            outputLabel = "Channel media relay failure. Error code: \(error.rawValue)"
        default: return
        }
        DispatchQueue.main.async {[weak self] in
            guard let weakself = self else { return }
            weakself.label = outputLabel
        }
    }
}

/// A view that displays the video feeds of all participants in a channel.
public struct ChannelRelayView: View {
    @ObservedObject public var agoraManager: RelayManager

    public var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    // Show the video feeds for each participant.
                    ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                        AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                            .aspectRatio(contentMode: .fit).cornerRadius(10)
                    }
                }.padding(20)
            }
            HStack {
                Spacer()
                Button {
                    Task { await self.agoraManager.channelRelayBtnClicked() }
                } label: {
                    if let mediaRelaying = agoraManager.mediaRelaying {
                        Text("\(mediaRelaying ? "Start" : "Stop") Relaying")
                    } else {
                        Text("Loading...").disabled(true)
                    }
                }

            }
        }.onAppear {
            agoraManager.agoraEngine.joinChannel(
                byToken: DocsAppConfig.shared.rtcToken,
                channelId: agoraManager.sourceChannel,
                info: nil, uid: DocsAppConfig.shared.uid
            )
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    init(sourceChannel: String, destChannel: String) {
        self.agoraManager = RelayManager(sourceChannel: sourceChannel, destChannel: destChannel)
    }

    public static let docPath = getFolderName(from: #file)
    public static let docTitle = LocalizedStringKey("live-streaming-over-multiple-channels-title")
}

struct ChannelRelayView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelRelayView(sourceChannel: "channel1", destChannel: "channel2")
    }
}
