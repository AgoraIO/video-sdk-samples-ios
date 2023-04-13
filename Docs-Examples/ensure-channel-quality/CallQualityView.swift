//
//  CallQualityView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

/**
 A custom Agora SDK manager for call quality.
 */
public class CallQualityManager: AgoraManager {
    /// A dictionary mapping user IDs to call quality statistics.
    @Published public var callQualities: [UInt: String] = [:]

    func startProbeTest() {
        // Configure a LastmileProbeConfig instance.
        let config = AgoraLastmileProbeConfig()
        // Probe the uplink network quality.
        config.probeUplink = true
        // Probe the downlink network quality.
        config.probeDownlink = true
        // The expected uplink bitrate (bps). The value range is [100000,5000000].
        config.expectedUplinkBitrate = 100000
        // The expected downlink bitrate (bps). The value range is [100000,5000000].
        config.expectedDownlinkBitrate = 100000

        agoraEngine.startLastmileProbeTest(config)
    }

    public func rtcEngine(_ engine: AgoraRtcEngineKit, lastmileProbeTest result: AgoraLastmileProbeResult) {
        agoraEngine.stopLastmileProbeTest()
        // The result object contains the detailed test results that help you
        // manage call quality. For example, the downlink jitter"
        print("downlink jitter: \(result.downlinkReport.jitter)")
    }

    /**
     Updates the call quality statistics for a remote user.

     - Parameter engine: The Agora SDK engine.
     - Parameter stats: The remote video statistics.
     */
    public func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStats stats: AgoraRtcRemoteVideoStats) {
        self.callQualities[stats.uid] = """
        Received Bitrate = \(stats.receivedBitrate)
        Frame = \(stats.width)x\(stats.height), \(stats.receivedFrameRate)fps
        Frame Loss Rate = \(stats.frameLossRate)
        Packet Loss Rate = \(stats.packetLossRate)
        """
    }

    /**
     Updates the call quality statistics for the local user.

     - Parameter engine: The Agora SDK engine.
     - Parameter stats: The local video statistics.
     - Parameter sourceType: The type of video source.
     */
    public func rtcEngine(_ engine: AgoraRtcEngineKit, localVideoStats stats: AgoraRtcLocalVideoStats, sourceType: AgoraVideoSourceType) {
        self.callQualities[0] = """
        Captured Frame = \(stats.captureFrameWidth)x\(stats.captureFrameHeight), \(stats.captureFrameRate)fps
        Encoded Frame = \(stats.encodedFrameWidth)x\(stats.encodedFrameHeight), \(stats.encoderOutputFrameRate)fps
        Sent Data = \(stats.sentFrameRate)fps, bitrate: \(stats.sentBitrate)
        Packet Loss Rate = \(stats.txPacketLossRate)
        """
    }
}

/**
 A view that displays the video feeds of all participants in a channel, along with their call quality statistics.
 */
struct CallQualityView: View {
    /// The Agora SDK manager for call quality.
    @ObservedObject var agoraManager = CallQualityManager(appId: AppKeys.agoraKey, role: .broadcaster)
    /// The channel ID to join.
    let channelId: String

    var body: some View {
        ScrollView {
            VStack {
                ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                    AgoraVideoCanvasView(agoraEngine: agoraManager.agoraEngine, uid: uid)
                        .aspectRatio(contentMode: .fit).cornerRadius(10)
                        .overlay(alignment: .topLeading) {
                            Text(agoraManager.callQualities[uid] ?? "no data").padding()
                        }
                }
            }.padding(20)
        }.onAppear {
            agoraManager.agoraEngine.joinChannel(byToken: AppKeys.agoraToken, channelId: channelId, info: nil, uid: 0)
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    init(channelId: String) {
        self.channelId = channelId
    }
}

struct CallQualityView_Previews: PreviewProvider {
    static var previews: some View {
        CallQualityView(channelId: "test")
    }
}
