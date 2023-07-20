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
        proxyResponse = self.agoraEngine.setCloudProxy(proxyType)
        if proxyType == .noneProxy { proxyState = .noneProxyType }
    }

    // swiftlint:disable:next function_parameter_count
    func rtcEngine(
        _ engine: AgoraRtcEngineKit, didProxyConnected channel: String,
        withUid uid: UInt, proxyType: AgoraProxyType, localProxyIp: String, elapsed: Int
    ) {
        proxyState = proxyType
    }
}

/// A view that authenticates the user with a token and joins them to a channel using Agora SDK.
struct CloudProxyView: View {
    /// The Agora SDK manager.
    @ObservedObject var agoraManager: CloudProxyManager

    /// Initializes a new ``CloudProxyView``.
    ///
    /// - Parameters:
    ///   - channelId: The channel ID to join.
    ///   - proxyType: Type of proxy to be used.
    public init(channelId: String, proxyType: AgoraCloudProxyType) {
        DocsAppConfig.shared.channel = channelId
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
        }.onAppear { await agoraManager.joinChannel(DocsAppConfig.shared.channel)
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
        case .httpProxyType:
            return "HTTP Proxy Connected"
        case .httpsProxyType:
            return "HTTPS Proxy Connected"
        @unknown default:
            return "Unknown Proxy State"
        }
    }
}
