//
//  TokenAuthenticationView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 21/06/2023.
//

import SwiftUI
import AgoraRtcKit


class CloudProxyManager: AgoraManager {

    @Published var proxyState: AgoraProxyType?
    @Published var proxyResponse: Int32 = 0

    init(appId: String, role: AgoraClientRole = .audience, proxyType: AgoraCloudProxyType) {
        super.init(appId: appId, role: role)
        proxyResponse = self.engine.setCloudProxy(proxyType)
        if proxyType == .noneProxy { proxyState = .noneProxyType }
    }

    func rtcEngine(
        _ engine: AgoraRtcEngineKit, didProxyConnected channel: String,
        withUid uid: UInt, proxyType: AgoraProxyType, localProxyIp: String, elapsed: Int
    ) {
        proxyState = proxyType
    }
}

/**
 * A view that authenticates the user with a token and joins them to a channel using Agora SDK.
 */
struct CloudProxyView: View {
    /// The Agora SDK manager.
    @ObservedObject var agoraManager: CloudProxyManager

    /// The channel ID to join.
    public let channelId: String

    /**
     * Initializes a new `TokenAuthenticationView`.
     *
     * - Parameter channelId: The channel ID to join.
     * - Parameter tokenUrl: The URL of the token server.
     */
    public init(channelId: String, proxyType: AgoraCloudProxyType) {
        self.channelId = channelId
        self.agoraManager = CloudProxyManager(
            appId: DocsAppConfig.shared.appId,
            role: .broadcaster, proxyType: proxyType
        )
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                        AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                            .aspectRatio(contentMode: .fit).cornerRadius(10)
                    }
                }.padding(20)
            }
            VStack {
                let text = agoraManager.proxyResponse < 0 ?
                    "Connection Error \(agoraManager.proxyResponse)" :
                    "Connecting"
                Text(agoraManager.proxyState == nil ? text : agoraManager.proxyState!.humanReadableString
                ).padding().background(.tertiary).cornerRadius(25).padding()
                Spacer()
            }.padding()
        }.onAppear { agoraManager.joinChannel(self.channelId)
        }.onDisappear { agoraManager.leaveChannel() }
    }
}

struct CloudProxyView_Previews: PreviewProvider {
    static var previews: some View {
        CloudProxyView(channelId: "test", proxyType: .noneProxy)
    }
}

extension AgoraProxyType {
    var humanReadableString: String {
        switch self {
        case .localProxyType:
            return "Local Proxy Connected"
        case .tcpProxyType:
            return "TCP Proxy Connected"
        case .udpProxyType:
            return "UDP Proxy Connected"
        case .tcpProxyAutoFallbackType:
            return "TCP Fallback Proxy Connected"
        case .noneProxyType:
            return "No Proxy Connected"
        @unknown default:
            return "Unknown Proxy State"
        }
    }
}
