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
    /// Callback method called when a video frame is captured.
    ///
    /// - Parameters:
    ///   - capture: The AgoraCameraSourcePush instance that captured the frame.
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
        let framePushed = self.engine.pushExternalVideoFrame(videoFrame)
        if !framePushed {
            print("Frame could not be pushed.")
        }
    }

    /// The capture device being used, for example, the ultra-wide back camera.
    var captureDevice: AVCaptureDevice?

    /// The AVCaptureVideoPreviewLayer that is updated by pushSource whenever a new frame is captured.
    ///
    /// This object is used to populate the local camera frames.
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    var pushSource: AgoraCameraSourcePush?

    /// Initializes a new instance of the CustomAudioVideoManager.
    ///
    /// - Parameters:
    ///   - appId: The Agora application ID.
    ///   - role: The client role.
    ///   - captureDevice: The AVCaptureDevice to be used for capturing video.
    init(appId: String, role: AgoraClientRole = .audience, captureDevice: AVCaptureDevice?) {
        self.captureDevice = captureDevice
        super.init(appId: appId, role: role)
        if captureDevice != nil {
            self.engine.setExternalVideoSource(
                true, useTexture: true, sourceType: .videoFrame
            )
            self.pushSource = AgoraCameraSourcePush(delegate: self)
        }
    }

    /// Joins the channel and starts capturing the video from the specified device.
    ///
    /// - Parameters:
    ///   - channel: The channel ID to join.
    ///   - token: The token for authentication (optional).
    ///   - uid: The user ID (optional).
    ///   - info: Additional information (optional).
    /// - Returns: The join channel result.
    @discardableResult
    override func joinChannel(_ channel: String, token: String? = nil, uid: UInt = 0, info: String? = nil) -> Int32 {
        let jc = super.joinChannel(channel, token: token, uid: uid, info: info)
        if let captureDevice {
            pushSource?.startCapture(ofDevice: captureDevice)
        }
        return jc
    }

    override func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        self.localUserId = uid
        if captureDevice == nil {
            self.allUsers.insert(uid)
        }
    }
}

/// A SwiftUI view that displays custom audio and video content.
struct CustomAudioVideoView: View {
    /// The Agora SDK manager for handling custom audio and video operations.
    @ObservedObject var agoraManager: CustomAudioVideoManager
    /// The channel ID to join.
    let channelId: String
    var customPreview = CustomVideoSourcePreview()

    var body: some View {
        ScrollView {
            VStack {
                // The local custom camera view
                AgoraCustomVideoCanvasView(canvas: customPreview, previewLayer: agoraManager.previewLayer)
                    .aspectRatio(contentMode: .fit).cornerRadius(10)
                // All remote camera views
                ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                    AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                        .aspectRatio(contentMode: .fit).cornerRadius(10)
                }
            }.padding(20)
        }.onAppear {
            agoraManager.joinChannel(channelId, token: DocsAppConfig.shared.rtcToken)
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    /// Initializes a new instance of the CustomAudioVideoView.
    ///
    /// - Parameters:
    ///   - channelId: The channel ID to join.
    ///   - customCamera: The AVCaptureDevice to be used for custom camera capture.
    init(channelId: String, customCamera: AVCaptureDevice?) {
        self.channelId = channelId
        self.agoraManager = CustomAudioVideoManager(appId: DocsAppConfig.shared.appId, role: .broadcaster, captureDevice: customCamera)
    }
}
