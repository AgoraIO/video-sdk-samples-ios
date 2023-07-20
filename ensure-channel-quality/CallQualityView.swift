//
//  CallQualityView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

/// A custom Agora SDK manager for call quality.
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
        engine.stopLastmileProbeTest()
        // The result object contains the detailed test results that help you
        // manage call quality. For example, the downlink jitter"
        print("downlink jitter: \(result.downlinkReport.jitter)")
    }

    /// Updates the call quality statistics for a remote user.
    ///
    /// - Parameters:
    ///   - engine: The Agora SDK engine.
    ///   - stats: The remote video statistics.
    ///
    public func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStats stats: AgoraRtcRemoteVideoStats) {
        self.callQualities[stats.uid] = """
        Received Bitrate = \(stats.receivedBitrate)
        Frame = \(stats.width)x\(stats.height), \(stats.receivedFrameRate)fps
        Frame Loss Rate = \(stats.frameLossRate)
        Packet Loss Rate = \(stats.packetLossRate)
        """
    }

    /// Updates the call quality statistics for the local user.
    ///
    /// - Parameters:
    ///   - engine: The Agora SDK engine.
    ///   - stats: The local video statistics.
    ///   - sourceType: The type of video source.
    public func rtcEngine(
        _ engine: AgoraRtcEngineKit, localVideoStats stats: AgoraRtcLocalVideoStats,
        sourceType: AgoraVideoSourceType
    ) {
        self.callQualities[self.localUserId] = """
        Captured Frame = \(stats.captureFrameWidth)x\(stats.captureFrameHeight), \(stats.captureFrameRate)fps
        Encoded Frame = \(stats.encodedFrameWidth)x\(stats.encodedFrameHeight), \(stats.encoderOutputFrameRate)fps
        Sent Data = \(stats.sentFrameRate)fps, bitrate: \(stats.sentBitrate)
        Packet Loss Rate = \(stats.txPacketLossRate)
        """
    }
}

/// A view that displays the video feeds of all participants in a channel, along with their call quality statistics.
struct CallQualityView: View {
    /// The Agora SDK manager for call quality.
    @ObservedObject var agoraManager = CallQualityManager(
        appId: DocsAppConfig.shared.appId, role: .broadcaster
    )

    var body: some View {
        ScrollView {
            VStack {
                ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                    AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                        .aspectRatio(contentMode: .fit).cornerRadius(10)
                        .overlay(alignment: .topLeading) {
                            Text(agoraManager.callQualities[uid] ?? "no data").padding(4)
                                .background {
                                    VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
                                        .cornerRadius(10).blur(radius: 1).opacity(0.75)
                                }.padding(4)
                        }
                }
            }.padding(20)
        }.onAppear {
            await agoraManager.joinChannel(DocsAppConfig.shared.channel)
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    init(channelId: String) {
        DocsAppConfig.shared.channel = channelId
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct CallQualityView_Previews: PreviewProvider {
    static var previews: some View {
        CallQualityView(channelId: "test")
    }
}
