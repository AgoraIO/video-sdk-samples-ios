//
//  GeofencingView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

class GeofencingManager: AgoraManager {
    let geoRegions: RegionsType
    init(appId: String, role: AgoraClientRole = .audience, geoRegions: RegionsType) {
        self.geoRegions = geoRegions
        super.init(appId: appId, role: role)
    }
    enum RegionsType: Hashable {
        case absolute(AgoraAreaCodeType)
        case inclusive([AgoraAreaCodeType])
        case exclusive([AgoraAreaCodeType])
    }
    override func setupEngine() -> AgoraRtcEngineKit {
        let engineConfig = AgoraRtcEngineConfig()
        engineConfig.appId = DocsAppConfig.shared.appId
        var combinedAreaCode: AgoraAreaCodeType!
        switch geoRegions {
        case .absolute(let region):
            combinedAreaCode = region
        case .inclusive(let regions):
            combinedAreaCode = AgoraAreaCodeType(rawValue: regions.reduce(0, { $0 | $1.rawValue }))!
        case .exclusive(let regions):
            combinedAreaCode = AgoraAreaCodeType(
                rawValue: AgoraAreaCodeType.global.rawValue ^ regions.reduce(0, { $0 | $1.rawValue })
            )!
        }
        engineConfig.areaCode = combinedAreaCode
        let eng = AgoraRtcEngineKit.sharedEngine(with: engineConfig, delegate: self)
        if DocsAppConfig.shared.product != .voice {
            eng.enableVideo()
        } else {
            eng.enableAudio()
        }
        eng.setClientRole(role)
        return eng
    }
}

/// A view that authenticates the user with a token and joins them to a channel using Agora SDK.
struct GeofencingView: View {
    /// The Agora SDK manager.
    @ObservedObject var agoraManager: GeofencingManager

    var body: some View {
        ZStack {
            self.basicScrollingVideos
            ToastView(message: $agoraManager.label)
        }.onAppear { await agoraManager.joinChannel(DocsAppConfig.shared.channel)
        }.onDisappear { agoraManager.leaveChannel() }
    }

    /// Initializes a new ``GeofencingView``.
    ///
    /// - Parameters:
    ///   - channelId: The channel ID to join.
    public init(channelId: String, regions: GeofencingManager.RegionsType) {
        DocsAppConfig.shared.channel = channelId
        agoraManager = GeofencingManager(
            appId: DocsAppConfig.shared.appId,
            role: .broadcaster,
            geoRegions: regions
        )
    }

    static let docPath = getFolderName(from: #file)
    static let docTitle = LocalizedStringKey("geofencing-title")
}

struct GeofencingView_Previews: PreviewProvider {
    static var previews: some View {
        GeofencingView(channelId: "test", regions: .absolute(.global))
    }
}
