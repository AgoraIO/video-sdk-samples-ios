//
//  RawMediaProcessingView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 24/07/2023.
//

import SwiftUI
import AgoraRtcKit

public class MediaProcessingManager: AgoraManager, HasModifyVideo, HasModifyAudio {

    // MARK: - Properties

    @Published var videoModification: VideoModification = .none
    @Published var audioModification: AudioModification = .none
    var videoFrameDelegate: ModifyVideoFrameDelegate?
    var audioFrameDelegate: ModifyAudioFrameDelegate?

    // MARK: - Agora Engine Functions

    override init(appId: String, role: AgoraClientRole = .audience) {
        super.init(appId: appId, role: role)

        // Video Setup
        self.videoFrameDelegate = ModifyVideoFrameDelegate(modifyController: self)
        agoraEngine.setVideoFrameDelegate(videoFrameDelegate)

        // Audio Setup
        self.audioFrameDelegate = ModifyAudioFrameDelegate(modifyController: self)
        agoraEngine.setAudioFrameDelegate(audioFrameDelegate)
        agoraEngine.setRecordingAudioFrameParametersWithSampleRate(
            44100, channel: 1, mode: .readWrite, samplesPerCall: 4410
        )
        agoraEngine.setMixedAudioFrameParametersWithSampleRate(
            44100, channel: 1, samplesPerCall: 4410
        )
        agoraEngine.setPlaybackAudioFrameParametersWithSampleRate(
            44100, channel: 1, mode: .readWrite, samplesPerCall: 4410
        )
    }
}

internal enum VideoModification: String, CaseIterable {
    case none
    case zoom
    case comic
    case invert
    case mirrorVertical // upside down
}

internal enum AudioModification: String, CaseIterable {
    case none
    case louder
    case reverb
}

// MARK: - UI

/// A view that displays the video feeds of all participants in a channel.
public struct RawMediaProcessingView: View {
    @ObservedObject public var agoraManager = MediaProcessingManager(
        appId: DocsAppConfig.shared.appId, role: .broadcaster
    )

    public var body: some View {
        ZStack {
            VStack {
                // Show a scrollable view of video feeds for all participants.
                self.basicScrollingVideos
                HStack {
                    Image(systemName: "photo")
                    Picker("Choose Video Modification", selection: $agoraManager.videoModification) {
                        ForEach([VideoModification.none, .comic, .invert, .zoom], id: \.rawValue) {
                            Text($0.rawValue).tag($0)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }.padding(.all.subtracting(.bottom))

                HStack {
                    Image(systemName: "speaker.wave.3")
                    Picker("Choose Audio Modification", selection: $agoraManager.audioModification) {
                        ForEach(
                            [AudioModification.none, .reverb, .louder], id: \.rawValue
                        ) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(SegmentedPickerStyle())
                }.padding()

            }
            ToastView(message: $agoraManager.label)
        }.onAppear {
            await agoraManager.joinChannel(
                DocsAppConfig.shared.channel,
                token: DocsAppConfig.shared.rtcToken,
                uid: DocsAppConfig.shared.uid
            )
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    init(channelId: String) {
        DocsAppConfig.shared.channel = channelId
    }
    public static let docPath = getFolderName(from: #file)
    public static let docTitle = LocalizedStringKey("stream-raw-audio-and-video-title")
}

struct RawMediaProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        RawMediaProcessingView(channelId: "test")
    }
}
