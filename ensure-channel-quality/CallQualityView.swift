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

    // MARK: - Properties

    /// A dictionary mapping user IDs to call quality statistics.
    @Published public var callQualities: [UInt: String] = [:]

    @Published public var streamType: [UInt: AgoraVideoStreamType] = [:]

    @Published public var lastMileQuality: AgoraNetworkQuality = .unknown

    // MARK: - Agora Engine Functions

    public override func setupEngine() -> AgoraRtcEngineKit {
        let engine = super.setupEngine()

        // Set Audio Scenario
        engine.setAudioScenario(.gameStreaming)

        // Enable dual stream mode
        engine.setDualStreamMode(.enableSimulcastStream)
        engine.setAudioProfile(.default)

        // Set the video configuration
        let videoConfig = AgoraVideoEncoderConfiguration(
            size: CGSize(width: 640, height: 360),
            frameRate: .fps10,
            bitrate: AgoraVideoBitrateStandard,
            orientationMode: .adaptative,
            mirrorMode: .auto
        )
        engine.setVideoEncoderConfiguration(videoConfig)

        return engine
    }
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

        print(agoraEngine.startLastmileProbeTest(config))
    }

    func setStreamQuality(for uid: UInt, to quality: AgoraVideoStreamType) {
        agoraEngine.setRemoteVideoStream(uid, type: quality)
    }

    // MARK: - Delegate Methods

    public func rtcEngine(_ engine: AgoraRtcEngineKit, lastmileQuality quality: AgoraNetworkQuality) {
        self.lastMileQuality = quality
    }

    public func rtcEngine(_ engine: AgoraRtcEngineKit, lastmileProbeTest result: AgoraLastmileProbeResult
    ) {
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

// MARK: - Property Helpers

extension AgoraNetworkQuality {
    var qualityDetails: (String, Color)? {
        switch self {
        case .excellent: return ("Excellent", .green)
        case .good: return ("Good", .blue)
        case .poor: return ("Poor", .yellow)
        case .bad: return ("Bad", .orange)
        case .vBad: return ("Very Bad", .red)
        case .down: return ("Down", .gray)
        case .unknown, .unsupported, .detecting: return nil
        @unknown default: return nil
        }
    }
}

// MARK: - UI

/// A view that displays the video feeds of all participants in a channel, along with their call quality statistics.
struct CallQualityView: View {
    /// The Agora SDK manager for call quality.
    @ObservedObject var agoraManager = CallQualityManager(
        appId: DocsAppConfig.shared.appId, role: .broadcaster
    )

    @State var channelJoined = false
    @State var betweenChannel = false

    func streamQualityOverlay(for uid: UInt) -> some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top) {
                self.callQualityOverlay(for: uid)
                Spacer()
                if uid != agoraManager.localUserId {
                    VStack(alignment: .trailing) {
                        Text("Stream Quality")
                        Toggle(isOn: qualityBinding(for: uid)) {}
                    }
                }
            }.padding(3)
            let streamType = agoraManager.streamType[uid] ?? .high
            RoundedRectangle(cornerRadius: 10).strokeBorder(
                (streamType == .low ? .red : .green)
            )
        }
    }

    var body: some View {
        ZStack {
            VStack {
                if let (qualityStr, color) = agoraManager.lastMileQuality.qualityDetails {
                    Text("Call Quality: \(qualityStr)")
                        .padding(4)
                        .background(color)
                        .cornerRadius(8)
                }
                ScrollView {
                    VStack {
                        ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                            AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                                .aspectRatio(contentMode: .fit).cornerRadius(10)
                                .overlay(alignment: .topLeading) {
                                    self.streamQualityOverlay(for: uid)
                                }
                        }
                    }.padding(20)
                }
                HStack {
                    if !self.channelJoined, !self.betweenChannel { Button {
                        self.agoraManager.agoraEngine.stopLastmileProbeTest()
                        self.agoraManager.startProbeTest()
                    } label: {
                        Text("Run Probe Test")
                            .foregroundColor(.primary).padding(5)
                            .background(.secondary).cornerRadius(5)
                    }}
                    Button {
                        if channelJoined {
                            self.channelJoined = agoraManager.leaveChannel(destroyInstance: false) != 0
                        } else {
                            betweenChannel = true
                            Task {
                                self.channelJoined = await agoraManager
                                    .joinChannel(DocsAppConfig.shared.channel) == 0
                                betweenChannel = false
                            }
                        }
                    } label: {
                        Text((self.channelJoined ? "Leave" : "Join") + " Channel")
                            .foregroundColor(.primary).padding(5)
                            .background(.secondary).cornerRadius(5)
                    }.disabled(betweenChannel)

                }
            }
            ToastView(message: $agoraManager.label)
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    private func qualityBinding(for key: UInt) -> Binding<Bool> {
        Binding<Bool>(
            get: { (self.agoraManager.streamType[key] ?? .high) == .high },
            set: { newValue in
                let newQuality = newValue ? AgoraVideoStreamType.high : .low
                self.agoraManager.streamType[key] = newQuality
                agoraManager.setStreamQuality(for: key, to: newQuality)
            }
        )
    }

    func callQualityOverlay(for uid: UInt) -> some View {
        Text(agoraManager.callQualities[uid] ?? "no data").padding(4).background {
            #if os(iOS)
            VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
                .cornerRadius(10).blur(radius: 1).opacity(0.75)
            #endif
        }.padding(4)
    }

    init(channelId: String) {
        DocsAppConfig.shared.channel = channelId
    }
    static let docPath = getFolderName(from: #file)
    static let docTitle = LocalizedStringKey("ensure-channel-quality-title")
}

struct CallQualityView_Previews: PreviewProvider {
    static var previews: some View {
        CallQualityView(channelId: "test")
    }
}
