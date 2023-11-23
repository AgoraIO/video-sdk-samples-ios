import Foundation
import AgoraRtcKit
import SwiftUI
import RealityKit

public class SpatialAudioManager: AgoraManager {

    var localSpatial: AgoraLocalSpatialAudioKit!

    func configureSpatialAudioEngine() {
        agoraEngine.setAudioProfile(.speechStandard)
        agoraEngine.setAudioScenario(.gameStreaming)

        // The next line is only required if using bluetooth headphones from iOS/iPadOS
        agoraEngine.setParameters(#"{"che.audio.force_bluetooth_a2dp":true}"#)

        agoraEngine.enableSpatialAudio(true)
        let localSpatialAudioConfig = AgoraLocalSpatialAudioConfig()
        localSpatialAudioConfig.rtcEngine = agoraEngine
        localSpatial = AgoraLocalSpatialAudioKit.sharedLocalSpatialAudio(with: localSpatialAudioConfig)

        // By default Agora subscribes to the audio streams of all remote users.
        // Unsubscribe all remote users; otherwise, the audio reception range you set
        // is invalid.
        localSpatial.muteLocalAudioStream(false)
        localSpatial.muteAllRemoteAudioStreams(false)

        // Set the audio reception range, in meters, of the local user
        localSpatial.setAudioRecvRange(50)
        // Set the length, in meters, of unit distance
        localSpatial.setDistanceUnit(1)
    }

    func updateLocalUser() {
        // Self position at origin, x-right, y-up, facing -Z axis
        let pos: [NSNumber]     = [0, 0, 0]
        let right: [NSNumber]   = [1, 0, 0]
        let up: [NSNumber]      = [0, 1, 0]
        let forward: [NSNumber] = [0, 0, -1]

        self.localSpatial.updateSelfPosition(
            pos,
            axisForward: forward,
            axisRight: right,
            axisUp: up
        )
    }

    func updateRemoteUser(_ uid: UInt, position: [NSNumber], forward: [NSNumber]) {
        let positionInfo = AgoraRemoteVoicePositionInfo()
        positionInfo.position = position
        positionInfo.forward = forward

        self.localSpatial.updateRemotePosition(
            uid, positionInfo: positionInfo
        )
    }

    // MARK: - Not required for using spatial audio

    func spatialPositionFromTransform(_ transform: Transform) -> (position: [NSNumber], forward: [NSNumber]) {
        let position = [
            transform.translation.x as NSNumber,
            transform.translation.y as NSNumber,
            transform.translation.z as NSNumber
        ]
        let forward = [
            transform.matrix.columns.2.x as NSNumber,
            transform.matrix.columns.2.y as NSNumber,
            transform.matrix.columns.2.z as NSNumber
        ]
        return (position, forward)
    }

    func updateRemoteUsers(with transform: Transform) {
        let (position, forward) = spatialPositionFromTransform(transform)
        self.allUsers.forEach { user in
            if user != self.localUserId {
                self.updateRemoteUser(user, position: position, forward: forward)
            }
        }

        let playerPos = AgoraRemoteVoicePositionInfo()
        playerPos.position = position
        playerPos.forward = forward
        localSpatial.updatePlayerPositionInfo(Int(mediaPlayer.getMediaPlayerId()), positionInfo: playerPos)
    }

    @Published var selectedIndex = 0

    public override func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        super.rtcEngine(engine, didJoinedOfUid: uid, elapsed: elapsed)
        let (pos, forward) = self.spatialPositionFromTransform(
            self.transform(for: self.selectedIndex)
        )
        self.updateRemoteUser(uid, position: pos, forward: forward)
    }

    // - MARK: Media player pieces, not required for spatial audio

    var mediaPlayer: AgoraRtcMediaPlayerProtocol!
    @Published var isPlaying: Bool?

    func setupMediaPlayer() {
        mediaPlayer = agoraEngine.createMediaPlayer(with: self)
        mediaPlayer.setLoopCount(10000)

        mediaPlayer.open(Bundle.main.url(forResource: "audiomixing", withExtension: "mp3")!.absoluteString, startPos: 0)

        localSpatial.setPlayerAttenuation(0.2, playerId: UInt(mediaPlayer.getMediaPlayerId()), forceSet: false)
    }
    func startStopPlayer() {
        guard let isPlaying else { return }
        if isPlaying {
            self.mediaPlayer.pause()
        } else {
            self.mediaPlayer.play()
        }
    }

    func transform(for index: Int) -> Transform {
        switch index {
        case 1...6: return Transform(
            rotation: simd_quatf(angle: .pi, axis: [0, 1, 0]),
            translation: [sin(Float(index) * .pi / 3), cos(Float(index) * .pi / 3), -1])
        default: return Transform(
            rotation: simd_quatf(angle: .pi, axis: [0, 1, 0]),
            translation: [0, 0, -1])
        }
    }
}

extension SpatialAudioManager: AgoraRtcMediaPlayerDelegate {
    // swiftlint:disable:next identifier_name
    public func AgoraRtcMediaPlayer(
        _ playerKit: AgoraRtcMediaPlayerProtocol,
        didChangedTo state: AgoraMediaPlayerState,
        error: AgoraMediaPlayerError
    ) {
        switch state {
        case .playBackAllLoopsCompleted: playerKit.stop()
        case .failed: Task { await self.updateLabel(to: "Playback failed") }
        case .playing, .paused, .stopped, .openCompleted:
            DispatchQueue.main.async {
                self.isPlaying = state == .playing
            }
        default: break
        }
    }
}

/// A view that displays the video feeds of all participants in a channel.
public struct SpatialAudioView: View {
    @ObservedObject public var agoraManager = SpatialAudioManager(
        appId: DocsAppConfig.shared.appId, role: .broadcaster
    )

    var radius: Double = 150

    var radialButtons: some View {
        ZStack {
            Button(action: {
                self.buttonTapped(0)
            }, label: {
                Image(systemName: "circle.circle.fill")
                    .tint(agoraManager.selectedIndex == 0 ? .green : .blue)
            })
            let piOThree = CGFloat.pi / 3

            ForEach(1..<7) { index in
                Button(action: {
                    self.buttonTapped(index)
                }, label: {
                    Image(systemName: "circle.circle.fill")
                        .tint(index == agoraManager.selectedIndex ? .green : .blue)
                })
                .offset(
                    x: sin(CGFloat(index) * piOThree) * 150,
                    y: -cos(CGFloat(index) * piOThree) * 150
                )
            }
        }
    }

    public var body: some View {
        VStack {
            Text("Select a button to choose remote audio location")
            self.radialButtons.frame(width: 350, height: 350)
            Spacer()
            ScrollView(.horizontal) { HStack {
                ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                    AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                        .aspectRatio(contentMode: .fit).cornerRadius(5)
                }
            }.padding(20) }.frame(height: 250)
            if let isPlaying = agoraManager.isPlaying {
                Button(action: {
                    agoraManager.startStopPlayer()
                }, label: {
                    Text("\(isPlaying ? "Stop" : "Start") media player")
                })
            }
        }.onAppear {
            await agoraManager.joinChannel(DocsAppConfig.shared.channel)
            agoraManager.configureSpatialAudioEngine()
            agoraManager.setupMediaPlayer()
        }.onDisappear {
            AgoraLocalSpatialAudioKit.destroy()
            agoraManager.mediaPlayer.stop()
            agoraManager.leaveChannel()
        }
    }

    func buttonTapped(_ index: Int) {
        // Handle the button tap here
        agoraManager.selectedIndex = index
        self.agoraManager.updateRemoteUsers(with: agoraManager.transform(for: index))
    }
    init(channelId: String) {
        DocsAppConfig.shared.channel = channelId
    }

    public static let docPath = getFolderName(from: #file)
    public static let docTitle = LocalizedStringKey("spatial-audio-title")
}

struct SpatialAudioView_Previews: PreviewProvider {
    static var previews: some View {
        SpatialAudioView(channelId: "test")
    }
}
