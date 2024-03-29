//
//  StreamMediaView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 24/07/2023.
//

import SwiftUI
import AgoraRtcKit

public class StreamMediaManager: AgoraManager, AgoraRtcMediaPlayerDelegate {

    // MARK: - Properties

    @Published var mediaPlaying: Bool = false
    @Published var mediaDuration: Int = 0
    @Published var playerButtonText = "Open Media File"
    var mediaPlayer: AgoraRtcMediaPlayerProtocol?

    // MARK: - Agora Engine Functions

    /// Starts streaming a video from a URL
    /// - Parameter url: Source URL of the media file. Could be local or remote.
    ///
    /// This method is picked up later by ``StreamMediaManager/AgoraRtcMzediaPlayer(_:didChangedTo:error:)``
    func startStreaming(from url: URL) {
        // Create an instance of the media player
        mediaPlayer = agoraEngine.createMediaPlayer(with: self)
        // Open the media file
        mediaPlayer!.open(url.path, startPos: 0)
        Task { await self.updateLabel(to: "Opening Media File...") }
    }

    /// Update the AgoraRtcChannelMediaOptions to control the media player publishing behavior.
    ///
    /// - Parameter publishMediaPlayer: A boolean value indicating whether the media player should be published or not.
    @discardableResult
    func updateChannelPublishOptions(publishingMedia: Bool) -> Int32 {
        defer { self.mediaPlaying = publishingMedia }

        let channelOptions = AgoraRtcChannelMediaOptions()

        // Set the options based on the `publishMediaPlayer` flag
        channelOptions.publishMediaPlayerAudioTrack = publishingMedia
        channelOptions.publishMediaPlayerVideoTrack = publishingMedia
        // If publishing media player, set the media player ID
        if publishingMedia { channelOptions.publishMediaPlayerId = Int(mediaPlayer!.getMediaPlayerId()) }

        // Set the regular camera to false if publishing media track
        channelOptions.publishMicrophoneTrack = true
        channelOptions.publishCameraTrack = !publishingMedia

        // Update the AgoraRtcChannel with the new media options
        return agoraEngine.updateChannel(with: channelOptions)
    }

    func playMedia() { self.mediaPlayer?.play() }
    func pauseMedia() { self.mediaPlayer?.pause() }
    func resumeMedia() { self.mediaPlayer?.resume() }

    // swiftlint:disable identifier_name
    /// This method is called when the AgoraRtcMediaPlayer changes its state.
    /// - Parameters:
    ///   - playerKit: The AgoraRtcMediaPlayerProtocol that triggered the state change.
    ///   - state: The new state of the media player.
    ///   - error: An optional error indicating the reason for the state change.
    public func AgoraRtcMediaPlayer(
        _ playerKit: AgoraRtcMediaPlayerProtocol,
        didChangedTo state: AgoraMediaPlayerState,
        error: AgoraMediaPlayerError
    ) {
        switch state {
        case .openCompleted:
            // Media file opened successfully
            // Update the UI, and start playing
            DispatchQueue.main.async {[weak self] in
                guard let weakself = self else { return }
                weakself.updateLabel(to: "Playback started")
                weakself.mediaDuration = weakself.mediaPlayer!.getDuration()

                weakself.updateChannelPublishOptions(publishingMedia: true)
                weakself.mediaPlayer?.play()
            }
        case .playBackAllLoopsCompleted:
            // Media file finished playing
            DispatchQueue.main.async {[weak self] in
                self?.updateLabel(to: "Playback finished")

                self?.updateChannelPublishOptions(publishingMedia: false)
            }
            // Clean up
            agoraEngine.destroyMediaPlayer(mediaPlayer)
            mediaPlayer = nil
        case .playing:
            // Media started playing
            break
        case .failed:
            // Media failed to play, check the URL
            DispatchQueue.main.async {[weak self] in
                self?.updateLabel(to: "playback failed: \(error.rawValue)")
            }
        default: break
        }
    }

    /// This method is called when the AgoraRtcMediaPlayer updates the playback position.
    /// - Parameters:
    ///   - playerKit: The AgoraRtcMediaPlayerProtocol that triggered the position change.
    ///   - position: The new position in the media file (in milliseconds).
    public func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo position: Int) {
        if mediaDuration > 0 {
            let result = (Float(position) / Float(mediaDuration))
            DispatchQueue.main.async { [weak self] in
                self?.updateLabel(to: "Playback progress: \(Int(result * 100))%")
            }
        }
    }
    // swiftlint:enable identifier_name

    @discardableResult
    public override func leaveChannel(
        leaveChannelBlock: ((AgoraChannelStats) -> Void)? = nil,
        destroyInstance: Bool = true
    ) -> Int32 {
        let leaveErr = self.agoraEngine.leaveChannel(leaveChannelBlock)
        defer { if destroyInstance { AgoraRtcEngineKit.destroy() } }
        self.allUsers.removeAll()
        return leaveErr
    }
}

// MARK: - UI

/// A view that displays the video feeds of all participants in a channel.
public struct StreamMediaView: View {
    @ObservedObject public var agoraManager = StreamMediaManager(appId: DocsAppConfig.shared.appId, role: .broadcaster)

    public var body: some View {
        ZStack {
            // Show a scrollable view of video feeds for all participants.
            VStack {
                ScrollView { VStack {
                    if agoraManager.mediaPlaying, let mediaPlayer = agoraManager.mediaPlayer {
                        AgoraVideoCanvasView(
                            manager: agoraManager,
                            canvasId: .mediaSource(
                                .mediaPlayer,
                                mediaPlayerId: mediaPlayer.getMediaPlayerId()
                            )
                        ).aspectRatio(contentMode: .fit).cornerRadius(10)
                    }
                    // Show the video feeds for each participant.
                    ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                        if !agoraManager.mediaPlaying || uid != self.agoraManager.localUserId {
                            AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                                .aspectRatio(contentMode: .fit).cornerRadius(10)
                        }
                    }
                }.padding(20) }
                if self.agoraManager.mediaPlaying {
                    // push this button before closing the media player
                    Button(action: {
                        agoraManager.mediaPlayer?.stop()
                        agoraManager.updateChannelPublishOptions(publishingMedia: false)
                        agoraManager.agoraEngine.destroyMediaPlayer(agoraManager.mediaPlayer)
                    }, label: {
                        Text("Stop Media")
                    }).padding()
                }
            }
            ToastView(message: $agoraManager.label)
        }.onAppear {
            #if os(macOS)
            (self.streamURL as NSURL?)?.startAccessingSecurityScopedResource()
            #endif
            await agoraManager.joinChannel(DocsAppConfig.shared.channel)
            agoraManager.startStreaming(from: streamURL)
        }.onDisappear {
            agoraManager.leaveChannel()
            #if os(macOS)
            (self.streamURL as NSURL?)?.stopAccessingSecurityScopedResource()
            #endif
        }
    }

    var streamURL: URL
    init(channelId: String, url: URL) {
        DocsAppConfig.shared.channel = channelId
        streamURL = url
    }
    static let docPath = getFolderName(from: #file)
    static let docTitle = LocalizedStringKey("play-media-title")
}

struct StreamMediaView_Previews: PreviewProvider {
    static var previews: some View {
        StreamMediaView(channelId: "test", url: URL(string: "")!)
    }
}
