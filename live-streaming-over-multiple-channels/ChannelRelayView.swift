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
    var primaryChannel: String
    var secondaryChannel: String
    var isRelay: Bool
    // Can be any number, the range is arbitrary
    var destUid: UInt = .random(in: 1000...5000)
    var exDelegate: ExDelegate!
    init(primaryChannel: String, secondaryChannel: String, isRelay: Bool) {
        self.primaryChannel = primaryChannel
        self.secondaryChannel = secondaryChannel
        self.isRelay = isRelay
        super.init(appId: DocsAppConfig.shared.appId, role: .broadcaster)
        self.exDelegate = ExDelegate(
            secondChannelIds: secondChannelIdsBinding,
            connection: AgoraRtcConnection(channelId: self.secondaryChannel, localUid: Int(self.destUid))
        )
    }
    func channelRelayBtnClicked() async {
        guard let mediaRelaying else { return }
        self.mediaRelaying = nil
        if isRelay {
            await relayMediaToggle(!mediaRelaying)
        } else {
            await joinChannelEx(!mediaRelaying)
        }
    }
    // MARK: - Join Channel Ex Example
    @Published var secondChannelIds: [AgoraVideoCanvasView.CanvasIdType] = []

    // Create a computed property that returns a Binding to secondChannelIds
    var secondChannelIdsBinding: Binding<[AgoraVideoCanvasView.CanvasIdType]> {
        Binding<[AgoraVideoCanvasView.CanvasIdType]>(
            get: { self.secondChannelIds },
            set: { self.secondChannelIds = $0 }
        )
    }

    func joinChannelEx(_ enable: Bool) async {
        let rtcSecondConnection = AgoraRtcConnection(channelId: self.secondaryChannel, localUid: Int(destUid))
        if !enable {
            /// This triggers ``ExDelegate-swift.class/rtcEngine(_:didLeaveChannelWith:)``
            let result = agoraEngine.leaveChannelEx(rtcSecondConnection, leaveChannelBlock: nil)
            DispatchQueue.main.async {
                self.mediaRelaying = false
                if result != 0 {
                    self.label = "leave channel failure: \(result)"
                } else {
                    self.label = "leaveChannelEx Success"
                }
            }
        } else {
            let mediaOptions = AgoraRtcChannelMediaOptions()
            mediaOptions.channelProfile = .liveBroadcasting
            mediaOptions.clientRoleType = .audience
            mediaOptions.autoSubscribeAudio = true
            mediaOptions.autoSubscribeVideo = true

            var destChannelToken: String?
            if !DocsAppConfig.shared.tokenUrl.isEmpty {
                destChannelToken = try? await self.fetchToken(
                    from: DocsAppConfig.shared.tokenUrl, channel: secondaryChannel, role: .broadcaster
                )
            }

            let result = agoraEngine.joinChannelEx(
                byToken: destChannelToken, connection: rtcSecondConnection,
                delegate: self.exDelegate, mediaOptions: mediaOptions
            )
            DispatchQueue.main.async {
                self.mediaRelaying = result == 0
                if result != 0 {
                    self.label = "join channel failure: \(result)"
                } else {
                    self.label = "joinChannelEx Success"
                }
            }
        }
    }

    /// A custom AgoraRtcEngineDelegate class for catching joinChannelEx events.
    public class ExDelegate: NSObject, AgoraRtcEngineDelegate {
        @Binding var secondChannelIds: [AgoraVideoCanvasView.CanvasIdType]
        let connection: AgoraRtcConnection
        /// Catch remote streams from the secondary channel
        public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
            secondChannelIds.append(.userIdEx(uid, connection))
        }
        /// Catch when the local user leaves the remote channel
        public func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
            secondChannelIds.removeAll()
        }
        /// Catch remote streams ended/left from the secondary channel
        public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
            self.secondChannelIds.removeAll { canvasId in
                switch canvasId {
                case .userIdEx(let uInt, _): return uInt == uid
                default: break
                }
                return false
            }
        }
        init(secondChannelIds: Binding<[AgoraVideoCanvasView.CanvasIdType]>, connection: AgoraRtcConnection) {
            self._secondChannelIds = secondChannelIds
            self.connection = connection
            super.init()
        }
    }

    // MARK: - Relay Media Example
    func relayMediaToggle(_ enable: Bool) async {
        if enable {
            agoraEngine.stopChannelMediaRelay()
        } else {
            var sourceChannelToken: String?
            if !DocsAppConfig.shared.tokenUrl.isEmpty {
                sourceChannelToken = try? await self.fetchToken(
                    from: DocsAppConfig.shared.tokenUrl, channel: primaryChannel, role: .broadcaster
                )
            }
            // Configure the source channel information.
            let srcChannelInfo = AgoraChannelMediaRelayInfo(token: sourceChannelToken)
            srcChannelInfo.channelName = primaryChannel
            srcChannelInfo.uid = 0
            let mediaRelayConfiguration = AgoraChannelMediaRelayConfiguration()
            mediaRelayConfiguration.sourceInfo = srcChannelInfo

            var destChannelToken: String?
            if !DocsAppConfig.shared.tokenUrl.isEmpty {
                destChannelToken = try? await self.fetchToken(
                    from: DocsAppConfig.shared.tokenUrl, channel: secondaryChannel, role: .broadcaster
                )
            }

            // Configure the destination channel information.
            let destChannelInfo = AgoraChannelMediaRelayInfo(token: destChannelToken)
            destChannelInfo.channelName = secondaryChannel
            destChannelInfo.uid = destUid
            mediaRelayConfiguration.setDestinationInfo(destChannelInfo, forChannelName: secondaryChannel)

            // Start relaying media streams across channels
            agoraEngine.startOrUpdateChannelMediaRelay(mediaRelayConfiguration)
        }
    }

    /// Occurs when the state of the media stream relay changes.
    /// - Parameters:
    ///   - engine: One AgoraRtcEngineKit object.
    ///   - state: The state code.
    ///   - error: The error code of the channel media relay.
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

// MARK: - UI

/// A view that displays the video feeds of all participants in a channel.
public struct ChannelRelayView: View {
    @ObservedObject public var agoraManager: RelayManager

    public var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    // Red border for the secondary channel streams
                    ForEach(Array(agoraManager.secondChannelIds), id: \.self) { idType in
                        AgoraVideoCanvasView(manager: agoraManager, canvasId: idType)
                            .aspectRatio(contentMode: .fit).cornerRadius(10).overlay(
                                RoundedRectangle(cornerRadius: 10).strokeBorder(Color.red)
                            )
                    }
                    // Green border for the primary channel streams
                    ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                        AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                            .aspectRatio(contentMode: .fit).cornerRadius(10).overlay(
                                RoundedRectangle(cornerRadius: 10).strokeBorder(Color.green)
                            )
                    }
                }.padding(20)
            }
            VStack {
                Spacer()
                Button {
                    Task { await self.agoraManager.channelRelayBtnClicked() }
                } label: {
                    if let mediaRelaying = agoraManager.mediaRelaying {
                        Text("\(mediaRelaying ? "Stop" : "Start") Relaying")
                    } else {
                        Text("Loading...").disabled(true)
                    }
                }
            }
            ToastView(message: $agoraManager.label)
        }.onAppear {
            await agoraManager.joinChannel(agoraManager.primaryChannel)
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    init(primaryChannel: String, secondaryChannel: String, isRelay: Bool = false) {
        self.agoraManager = RelayManager(
            primaryChannel: primaryChannel, secondaryChannel: secondaryChannel, isRelay: isRelay
        )
    }

    public static let docPath = getFolderName(from: #file)
    public static let docTitle = LocalizedStringKey("live-streaming-over-multiple-channels-title")
}

struct ChannelRelayView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelRelayView(primaryChannel: "channel1", secondaryChannel: "channel2")
    }
}
