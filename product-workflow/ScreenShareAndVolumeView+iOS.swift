//
//  ScreenShareAndVolumeView+macOS.swift
//  Docs-Examples
//
//  Created by Max Cobb on 21/11/2023.
//

import AgoraRtcKit
import CoreGraphics

#if os(iOS)
extension ScreenShareVolumeManager {
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

    fileprivate func publishScreenCaptureTrack(_ connection: AgoraRtcConnection) {
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
                self.publishScreenCaptureTrack(connection)
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
}
#endif
