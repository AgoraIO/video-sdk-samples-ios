//
//  SampleHandler.swift
//  screenSharer
//
//  Created by Max Cobb on 24/05/2023.
//

import ReplayKit
import AgoraRtcKit
import AgoraReplayKitExtension

class SampleHandler: AgoraReplayKitHandler {}
/*
class SampleHandler: RPBroadcastSampleHandler, AgoraRtcEngineDelegate {
    /// Engine instance required for sharing the screen.
    var engine: AgoraRtcEngineKit {
        let config = AgoraRtcEngineConfig()
        config.appId = DocsAppConfig.shared.appId
        config.channelProfile = .liveBroadcasting
        let agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraEngine.enableVideo()
        agoraEngine.setExternalVideoSource(true, useTexture: true, sourceType: .videoFrame)
        let videoConfig = AgoraVideoEncoderConfiguration(
            size: videoDimension, frameRate: .fps10, bitrate: AgoraVideoBitrateStandard,
            orientationMode: .adaptative, mirrorMode: .auto
        )
        agoraEngine.setVideoEncoderConfiguration(videoConfig)

        agoraEngine.setAudioProfile(.default)
        agoraEngine.setExternalAudioSource(true, sampleRate: 44100, channels: 2)
        return agoraEngine
    }

    // Get the screen size and orientation
    private let videoDimension: CGSize = {
        let screenSize = UIScreen.main.currentMode!.size
        var boundingSize = CGSize(width: 540, height: 980)
        let vidWidth = boundingSize.width / screenSize.width
        let vidHeight = boundingSize.height / screenSize.height
        if vidHeight < vidWidth {
            boundingSize.width = boundingSize.height / screenSize.height * screenSize.width
        } else if vidWidth < vidHeight {
            boundingSize.height = boundingSize.width / screenSize.width * screenSize.height
        }
        return boundingSize
    }()

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        guard let channel = UserDefaults(suiteName: "group.uk.rocketar.Docs-Examples")?.string(forKey: "channel") else {
            // Failed to get channel
            self.broadcastFinished()
            return
        }
        let channelMediaOptions = AgoraRtcChannelMediaOptions()
        channelMediaOptions.publishMicrophoneTrack = false
        channelMediaOptions.publishCameraTrack = false
        channelMediaOptions.publishCustomVideoTrack = true
        channelMediaOptions.publishCustomAudioTrack = true
        channelMediaOptions.autoSubscribeAudio = false
        channelMediaOptions.autoSubscribeVideo = false
        channelMediaOptions.clientRoleType = .broadcaster

        engine.joinChannel(
            byToken: DocsAppConfig.shared.rtcToken, channelId: channel,
            uid: DocsAppConfig.shared.screenShareId,
            mediaOptions: channelMediaOptions
        )
    }

    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }

    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }

    override func broadcastFinished() {
        engine.leaveChannel()
        AgoraRtcEngineKit.destroy()
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            self.sendVideoBuffer(sampleBuffer)
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }

    public func sendVideoBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        var rotation: Int32 = 0
        if let orientationAttachment = CMGetAttachment(
            sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil
        ) as? NSNumber {
            if let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) {
                switch orientation {
                case .up, .upMirrored: rotation = 0
                case .down, .downMirrored: rotation = 180
                case .left, .leftMirrored: rotation = 90
                case .right, .rightMirrored: rotation = 270
                default:   break
                }
            }
        }
        let time = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000 * 1000)

        let frame = AgoraVideoFrame()
        frame.format = 12
        frame.time = time
        frame.textureBuf = videoFrame
        frame.rotation = rotation
        self.engine.pushExternalVideoFrame(frame)
    }
}
*/
