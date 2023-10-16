//
//  ScreenShareAndVolumeView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import ReplayKit
import AgoraRtcKit

class ScreenShareVolumeManager: AgoraManager {
    @discardableResult
    /// Set the remote playback or local recording volume.
    /// - Parameters:
    ///   - id: ID for the user volume to change.
    ///   - volume: Playback or local recording volume.
    /// - Returns: Error code, 0 = success, &lt; 0 = failure.
    func setVolume(for id: UInt, to volume: Int) -> Int32 {
        if id == self.localUserId {
            return self.agoraEngine.adjustRecordingSignalVolume(volume)
        } else {
            return self.agoraEngine.adjustUserPlaybackSignalVolume(id, volume: Int32(volume))
        }
    }

    /// Limited IDs reserved for screen sharing.
    /// This way we know what's a screen share, and what's a regular camera.
    /// Our regular UID can be set in a similar way.
    var screenShareID = Int.random(in: 1000...1200)

    var screenShareToken: String?

    #if os(iOS)
    /// Start the socket that listens for the screen share frames
    /// which come from the broadcast extension.
    func setupScreenSharing() {
        let capParams = AgoraScreenCaptureParameters2()
        capParams.captureAudio = false
        capParams.captureVideo = true
        agoraEngine.startScreenCapture(capParams)
    }

    /// Broadcast picker to start and stop screen sharing.
    var broadcastPicker: RPSystemBroadcastPickerWrapper {
        // screenSharer is the name of the broadcast extension in this app's case.
        // If we can find the extension, apply the broadcast picker preferred extension
        var bundleIdentifier: String?
        if let url = Bundle.main.url(forResource: "screenSharer", withExtension: "appex", subdirectory: "PlugIns"),
           let bundle = Bundle(url: url) {
            bundleIdentifier = bundle.bundleIdentifier
        }
        return RPSystemBroadcastPickerWrapper(preferredExtension: bundleIdentifier)
    }

    public func rtcEngine(
        _ engine: AgoraRtcEngineKit, localVideoStateChangedOf state: AgoraVideoLocalState,
        error: AgoraLocalVideoStreamError, sourceType: AgoraVideoSourceType
    ) {
        // This delegate method catches whenever a screen is being shared
        // from a broadcast extension
        if sourceType == .screen {
            let connection = AgoraRtcConnection(
                channelId: DocsAppConfig.shared.channel,
                localUid: screenShareID
            )
            switch state {
            case .capturing:
                // The broadcast extension has started capturing frames
                let mediaOptions = AgoraRtcChannelMediaOptions()
                mediaOptions.publishCameraTrack = false
                mediaOptions.publishMicrophoneTrack = false
                mediaOptions.publishScreenCaptureAudio = false
                mediaOptions.publishScreenCaptureVideo = true
                mediaOptions.clientRoleType = .broadcaster
                mediaOptions.autoSubscribeAudio = false

                agoraEngine.joinChannelEx(
                    byToken: self.screenShareToken, connection: connection,
                    delegate: nil, mediaOptions: mediaOptions
                )
            case .encoding: break
            case .stopped, .failed:
                // The broadcast extension has finished capturing frames
                agoraEngine.leaveChannelEx(connection)
            @unknown default: break
            }
        }
    }

    override func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        // don't display our own screen share
        if uid != screenShareID {
            super.rtcEngine(engine, didJoinedOfUid: uid, elapsed: elapsed)
        }
    }
#endif
}

/// A view that displays the video feeds of all participants in a channel, along with sliders for volume control.
/// This view displays a ``RPSystemBroadcastPickerWrapper`` at the bottom,
/// which is a light wrapper of the broadcast picker from ReplayKit.
struct ScreenShareAndVolumeView: View {
    @State var volumeSetting: [UInt: Double] = [:]

    /// The Agora SDK manager for call quality.
    @ObservedObject var agoraManager = ScreenShareVolumeManager(
        appId: DocsAppConfig.shared.appId, role: .broadcaster
    )

    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                        AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                            .aspectRatio(contentMode: .fit).cornerRadius(10)
                            .overlay(alignment: .topLeading) {
                                VStack {
                                    Spacer()
                                    Slider(value: volumeBinding(for: uid), in: 0...100, step: 10)
                                }.padding()
                            }
                    }
                }.padding(20)
            }
            ToastView(message: $agoraManager.label)
        }.onAppear {
            await agoraManager.joinChannel(
                DocsAppConfig.shared.channel, uid: UInt.random(in: 1500...100_000)
            )
            agoraManager.setupScreenSharing()
            agoraManager.screenShareToken = DocsAppConfig.shared.rtcToken
            if !DocsAppConfig.shared.tokenUrl.isEmpty {
                // try to fetch a valid token, ready for sharing our screen.
                agoraManager.screenShareToken = try? await agoraManager.fetchToken(
                    from: DocsAppConfig.shared.tokenUrl,
                    channel: DocsAppConfig.shared.channel,
                    role: .broadcaster,
                    userId: UInt(agoraManager.screenShareID)
                )
            }
        }.onDisappear { agoraManager.leaveChannel() }
        #if os(iOS)
        Group { agoraManager.broadcastPicker }
            .frame(height: 44).padding().background(.tertiary)
        #endif
    }

    private func volumeBinding(for key: UInt) -> Binding<Double> {
        Binding<Double>(
            get: { self.volumeSetting[key] ?? 100.0 },
            set: { newValue in
                self.volumeSetting[key] = newValue
                agoraManager.setVolume(for: key, to: Int(newValue))
            }
        )
    }
    init(channelId: String) {
        DocsAppConfig.shared.channel = channelId
    }
    static let docPath = getFolderName(from: #file)
    static let docTitle = LocalizedStringKey("product-workflow-title")
}
