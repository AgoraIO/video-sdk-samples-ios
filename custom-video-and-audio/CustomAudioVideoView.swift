//
//  CustomAudioVideoView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 23/06/2023.
//

import SwiftUI
import AVKit
import AgoraRtcKit

/// A manager class that handles custom audio and video operations using Agora SDK.
class CustomAudioVideoManager: AgoraManager, AgoraCameraSourcePushDelegate {

    /// The video device being used, for example, the ultra-wide back camera.
    var videoCaptureDevice: AVCaptureDevice

    /// The audio device being used.
    var audioCaptureDevice: AVCaptureDevice

    /// The AVCaptureVideoPreviewLayer that is updated by pushSource whenever a new frame is captured.
    ///
    /// This object is used to populate the local camera frames.
    @Published var previewLayer: AVCaptureVideoPreviewLayer?

    /// The AgoraCameraSourcePush object responsible for capturing video frames
    /// from the capture device and sending it to the delegate, ``CustomAudioVideoManager``.
    public var cameraPushSource: AgoraCameraSourcePush?

    public var micPushSource: AgoraAudioSourcePush?

    // Not used currently
    var audioTrackId: Int32?

    /// Callback method called when a video frame is captured.
    ///
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer of the captured video frame.
    ///   - rotation: The rotation angle of the captured video frame.
    ///   - timeStamp: The time stamp of the captured video frame.
    func myVideoCapture(_ pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        let videoFrame = AgoraVideoFrame()
        videoFrame.format = 12
        videoFrame.textureBuf = pixelBuffer
        videoFrame.time = timeStamp
        videoFrame.rotation = Int32(rotation)

        // Push the video frame to the Agora SDK
        let framePushed = self.agoraEngine.pushExternalVideoFrame(videoFrame)
        if !framePushed {
            print("Frame could not be pushed.")
        }
    }

    /// Initializes a new instance of the CustomAudioVideoManager.
    ///
    /// - Parameters:
    ///   - appId: The Agora application ID.
    ///   - role: The client role.
    ///   - captureDevice: The AVCaptureDevice to be used for capturing video.
    init(
        appId: String, role: AgoraClientRole = .audience,
        videoCaptureDevice: AVCaptureDevice, audioCaptureDevice: AVCaptureDevice
    ) {
        self.videoCaptureDevice = videoCaptureDevice
        self.audioCaptureDevice = audioCaptureDevice
        super.init(appId: appId, role: role)

        self.agoraEngine.setExternalVideoSource(true, useTexture: true, sourceType: .videoFrame)
        self.cameraPushSource = AgoraCameraSourcePush(
            videoDevice: videoCaptureDevice,
            onVideoFrameCaptured: self.myVideoCapture(_:rotation:timeStamp:)
        )
        self.previewLayer = self.cameraPushSource?.previewLayer
        self.agoraEngine.setExternalAudioSource(true, sampleRate: 44100, channels: 1)

        self.micPushSource = AgoraAudioSourcePush(
            audioDevice: audioCaptureDevice,
            onAudioFrameCaptured: self.audioFrameCaptured(buf:)
        )
    }

    func audioFrameCaptured(buf: CMSampleBuffer) {
        agoraEngine.pushExternalAudioFrameSampleBuffer(buf)
    }

    /// Joins the channel and starts capturing the video from the specified device.
    ///
    /// - Parameters:
    ///   - channel: The channel ID to join.
    ///   - token: The token for authentication (optional).
    ///   - uid: The user ID (optional).
    ///   - mediaOptions: AgoraRtcChannelMediaOptions object for join settings
    /// - Returns: The join channel result.
    @discardableResult
    override func joinChannel(
        _ channel: String, token: String? = nil, uid: UInt = 0,
        mediaOptions: AgoraRtcChannelMediaOptions? = nil
    ) async -> Int32 {
        defer {
            cameraPushSource?.startCapturing()
            micPushSource?.startCapturing()
        }
        let opt = AgoraRtcChannelMediaOptions()
        opt.publishMicrophoneTrack = false
        opt.publishCustomAudioTrack = true
        // Not used currently
//        opt.publishCustomAudioTrackId = Int(self.audioTrackId ?? 0)
        return await super.joinChannel(channel, token: token, uid: uid, mediaOptions: opt)
    }

    @discardableResult
    override func leaveChannel(
        leaveChannelBlock: ((AgoraChannelStats) -> Void)? = nil,
        destroyInstance: Bool = true
    ) -> Int32 {
        // Need to stop the capture on exit
        cameraPushSource?.stopCapturing()
        cameraPushSource = nil
        micPushSource?.stopCapturing()
        micPushSource = nil
        return super.leaveChannel(leaveChannelBlock: leaveChannelBlock, destroyInstance: destroyInstance)
    }

    override func rtcEngine(
        _ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int
    ) {
        // Do not add local user to allUsers, because the camera
        // will be shown differently.
        // self.allUsers.insert(uid)

        self.localUserId = uid
    }
}

/// A SwiftUI view that displays custom audio and video content.
struct CustomAudioVideoView: View {
    /// The Agora SDK manager for handling custom audio and video operations.
    @ObservedObject var agoraManager: CustomAudioVideoManager
    var customPreview = CustomVideoSourcePreview()

    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    // The local custom camera view
                    AgoraCustomVideoCanvasView(
                        canvas: customPreview, previewLayer: agoraManager.previewLayer
                    ).aspectRatio(contentMode: .fit).cornerRadius(10)
                    // All remote camera views
                    self.innerScrollingVideos
                }.padding(20)
            }
            ToastView(message: $agoraManager.label)
        }.onAppear {
            await agoraManager.joinChannel(DocsAppConfig.shared.channel)
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    /// Initializes a new instance of the CustomAudioVideoView.
    ///
    /// - Parameters:
    ///   - channelId: The channel ID to join.
    ///   - customCamera: The AVCaptureDevice to be used for custom camera capture.
    init(channelId: String, customCamera: AVCaptureDevice, customMic: AVCaptureDevice) {
        DocsAppConfig.shared.channel = channelId
        self.agoraManager = CustomAudioVideoManager(
            appId: DocsAppConfig.shared.appId, role: .broadcaster,
            videoCaptureDevice: customCamera, audioCaptureDevice: customMic
        )
    }
    static let docPath = getFolderName(from: #file)
    static let docTitle = LocalizedStringKey("custom-video-and-audio-title")
}
