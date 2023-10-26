//
//  GettingStartedView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

public class RelayManager: AgoraManager {
    var primaryChannel: String
    var secondaryChannel: String

    var secondConnection: AgoraRtcConnection {
        AgoraRtcConnection(
            channelId: self.secondaryChannel,
            localUid: Int(destUid)
        )
    }

    // Can be any number, the range is arbitrary
    var destUid: UInt = .random(in: 1000...5000)
    lazy var exDelegate: ExDelegate = {
        ExDelegate(
            secondChannelIds: secondChannelIdsBinding,
            connection: AgoraRtcConnection(channelId: self.secondaryChannel, localUid: Int(self.destUid))
        )
    }()

    func joinChannelEx(token: String?) -> Int32 {
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.channelProfile = .liveBroadcasting
        mediaOptions.clientRoleType = .audience
        mediaOptions.autoSubscribeAudio = true
        mediaOptions.autoSubscribeVideo = true

        return agoraEngine.joinChannelEx(
            byToken: token, connection: self.secondConnection,
            delegate: self.exDelegate, mediaOptions: mediaOptions
        )
    }

    func leaveChannelEx() -> Int32 {
        agoraEngine.leaveChannelEx(self.secondConnection, leaveChannelBlock: nil)
    }

    @discardableResult
    func setupMediaRelay(
        sourceToken: String?, destinationToken: String?
    ) -> Int32 {
        // Configure the source channel information.
        let srcChannelInfo = AgoraChannelMediaRelayInfo(token: sourceToken)
        srcChannelInfo.channelName = self.primaryChannel
        srcChannelInfo.uid = 0
        let mediaRelayConfiguration = AgoraChannelMediaRelayConfiguration()
        mediaRelayConfiguration.sourceInfo = srcChannelInfo

        // Configure the destination channel information.
        let destChannelInfo = AgoraChannelMediaRelayInfo(token: destinationToken)
        destChannelInfo.channelName = self.secondaryChannel
        destChannelInfo.uid = self.destUid
        mediaRelayConfiguration.setDestinationInfo(
            destChannelInfo, forChannelName: self.secondaryChannel
        )

        // Start relaying media streams across channels
        return agoraEngine.startOrUpdateChannelMediaRelay(mediaRelayConfiguration)
    }

    @discardableResult
    func stopMediaRelay() -> Int32 {
        agoraEngine.stopChannelMediaRelay()
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
        switch state {
        case .connecting:
            // Channel media relay is connecting.
            break
        case .running:
            // Channel media relay is running.
            break
        case .failure:
            // Channel media relay failure
            break
        default: return
        }
        Task { await self.updateMediaRelayLabel(with: state, error: error) }
    }

    // MARK: - Manager setup

    var mediaRelaying: Bool? = false
    var isRelay: Bool

    init(primaryChannel: String, secondaryChannel: String, isRelay: Bool) {
        self.primaryChannel = primaryChannel
        self.secondaryChannel = secondaryChannel
        self.isRelay = isRelay
        super.init(appId: DocsAppConfig.shared.appId, role: .broadcaster)
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

    @Published var secondChannelIds: [AgoraVideoCanvasView.CanvasIdType] = []

    // Create a computed property that returns a Binding to secondChannelIds
    var secondChannelIdsBinding: Binding<[AgoraVideoCanvasView.CanvasIdType]> {
        Binding<[AgoraVideoCanvasView.CanvasIdType]>(
            get: { self.secondChannelIds },
            set: { self.secondChannelIds = $0 }
        )
    }

    func joinChannelEx(_ enable: Bool) async {
        if !enable {
            /// This triggers ``ExDelegate-swift.class/rtcEngine(_:didLeaveChannelWith:)``
            let result = self.leaveChannelEx()
            DispatchQueue.main.async {
                self.mediaRelaying = false
                if result != 0 {
                    self.updateLabel(to: "leave channel failure: \(result)")
                } else {
                    self.updateLabel(to: "leaveChannelEx Success")
                }
            }
        } else {
            var destChannelToken: String?
            if !DocsAppConfig.shared.tokenUrl.isEmpty {
                destChannelToken = try? await self.fetchToken(
                    from: DocsAppConfig.shared.tokenUrl, channel: secondaryChannel, role: .broadcaster
                )
            }

            let result = self.joinChannelEx(token: destChannelToken)
            DispatchQueue.main.async {
                self.mediaRelaying = result == 0
                if result != 0 {
                    self.updateLabel(to: "join channel failure: \(result)")
                } else {
                    self.updateLabel(to: "joinChannelEx Success")
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
            self.stopMediaRelay()
        } else {
            var sourceChannelToken: String?
            if !DocsAppConfig.shared.tokenUrl.isEmpty {
                sourceChannelToken = try? await self.fetchToken(
                    from: DocsAppConfig.shared.tokenUrl, channel: primaryChannel, role: .broadcaster
                )
            }

            var destChannelToken: String?
            if !DocsAppConfig.shared.tokenUrl.isEmpty {
                destChannelToken = try? await self.fetchToken(
                    from: DocsAppConfig.shared.tokenUrl, channel: secondaryChannel, role: .broadcaster
                )
            }

            self.setupMediaRelay(
                sourceToken: sourceChannelToken,
                destinationToken: destChannelToken
            )
        }
    }

    @MainActor
    func updateMediaRelayLabel(with state: AgoraChannelMediaRelayState, error: AgoraChannelMediaRelayError) async {
        switch state {
        case .connecting:
            self.updateLabel(to: "Channel media relay is connecting.")
        case .running:
            self.mediaRelaying = true
            self.updateLabel(to: "Channel media relay is running.")
        case .failure:
            self.mediaRelaying = false
            self.updateLabel(to: "Channel media relay failure. Error code: \(error.rawValue)")
        default: return
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
            primaryChannel: primaryChannel,
            secondaryChannel: secondaryChannel,
            isRelay: isRelay
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
