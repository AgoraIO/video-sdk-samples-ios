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

    func muteLocalUser() {
        self.agoraEngine.muteLocalAudioStream(true)
    }

    func unmuteLocalUser() {
        self.agoraEngine.muteLocalAudioStream(false)
    }

    func muteRemoteUser(uid: UInt, isMuted: Bool) {
        self.agoraEngine.muteRemoteAudioStream(uid, mute: isMuted)
    }

    #if os(iOS)
    /// Limited IDs reserved for screen sharing.
    /// This way we know what's a screen share, and what's a regular camera.
    /// Our regular UID can be set in a similar way.
    var screenShareID = Int.random(in: 1000...1200)

    var screenShareToken: String?

    #elseif os(macOS)

    @Published var groupedScreens: [String: [AgoraScreenCaptureSourceInfo]] = [:]

    @Published var screenSharingActive = false

    @discardableResult
    override func leaveChannel(
        leaveChannelBlock: ((AgoraChannelStats) -> Void)? = nil,
        destroyInstance: Bool = true
    ) -> Int32 {
        self.stopScreenShare()
        return super.leaveChannel(
            leaveChannelBlock: leaveChannelBlock,
            destroyInstance: destroyInstance
        )
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

    #if os(macOS)
    @State var showPopup = false
    @State var selectedScreenName: String = ""
    @State var selectedScreen: CGWindowID?
    @State var screenSharingActive = false
    #endif

    var body: some View {
        ZStack {
            VStack {
                ScrollView { VStack {
                    ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                        AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                            .aspectRatio(contentMode: .fit).cornerRadius(10)
                            .overlay(alignment: .topLeading) { VStack {
                                Spacer()
                                Slider(value: volumeBinding(for: uid), in: 0...100, step: 10)
                            }.padding() }
                    }
                }.padding(20) }
                Group {
                    #if os(iOS)
                    agoraManager.broadcastPicker
                    #elseif os(macOS)
                    Button {
                        if self.screenSharingActive {
                            self.stopScreenshare()
                        } else {
                            self.showScreenshareModal()
                        }
                    } label: {
                        Text(self.screenSharingActive ? "Stop sharing" : "Share screen")
                    }
                    #endif
                }.frame(height: 44).padding(3).background(.tertiary).padding(3)
            }
            ToastView(message: $agoraManager.label)
        }
        #if os(macOS)
        .sheet(isPresented: self.$showPopup, content: {
            ScreenShareModal(displayed: self.$showPopup,
                screens: agoraManager.groupedScreens,
                             startScreenShare: self.startScreenshare(with:)
            ).frame(width: self.popupWidth, height: self.popupHeight)
        })
        #endif
        .onAppear {
            await agoraManager.joinChannel(
                DocsAppConfig.shared.channel, uid: UInt.random(in: 1500...100_000)
            )
            #if os(iOS)
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
            #endif
        }.onDisappear { agoraManager.leaveChannel() }
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
