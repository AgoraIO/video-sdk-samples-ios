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

    /// joinChannel override to set the userdefaults channel name
    /// - Parameters:
    ///   - channel: Channel to join
    /// - Returns: Join channel error code. 0 = Success, &lt;0 = Failure
    @discardableResult
    override func joinChannel(_ channel: String, uid: UInt? = nil) async -> Int32 {
        let rtnCode = await super.joinChannel(channel, uid: uid)

        // suiteName is the App Group assigned to the main app and the broadcast extension.
        // This sets the channel name so the broadcast extension can join the same channel.
        let userDefaults = UserDefaults(suiteName: "group.uk.rocketar.Docs-Examples")
        userDefaults?.set(channel, forKey: "channel")

        return rtnCode
    }

    #if os(iOS)
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
        }.onAppear { await agoraManager.joinChannel(DocsAppConfig.shared.channel)
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
