//
//  ProxyInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 21/06/2023.
//

import SwiftUI
import AgoraRtcKit

/// A protocol for views that require a proxy type for cloud proxy.
public protocol HasProxyServerInput: View {
    init(channelId: String, proxyType: AgoraCloudProxyType)
}

extension CloudProxyView: HasProxyServerInput {}

/// ProxyType is an internal type just for representing the picker to select a proxy.
enum ProxyType: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case none
    case tcp
    case udp
    func agoraProxyType() -> AgoraCloudProxyType {
        switch self {
        case .none: return .noneProxy
        case .tcp: return .tcpProxy
        case .udp: return .udpProxy
        }
    }
}

/// A view that allows the user to input a channel ID and a proxy selection,
/// and then navigates to a view that accepts both of those parameters.
///
/// The `ProxyInputView` takes a generic parameter `Content` that conforms to the `HasProxyServerInput` protocol.
/// It shows two input fields for entering the channel ID and type of proxy server, respectively,
/// and a navigation link that navigates to `Content` when the "Join Channel" button is pressed.
/// The navigation link is disabled if the channel name is empty.
public struct ProxyInputView<Content: HasProxyServerInput>: View {
    /// The channel ID entered by the user.
    @State private var channelId: String = DocsAppConfig.shared.channel
    /// The proxy type chosen by the user.
    @State private var proxyType: ProxyType = .init(
        rawValue: DocsAppConfig.shared.proxyType
    ) ?? .none
    /// The type of view to navigate to after the user inputs the channel ID and token URL.
    public var continueTo: Content.Type
    public var body: some View {
        VStack {
            Spacer()
            TextField("Enter channel id", text: $channelId)
                .textFieldStyle(.roundedBorder).padding([.horizontal, .top])
            Picker("Choose Proxy Type", selection: $proxyType) {
                ForEach(ProxyType.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(SegmentedPickerStyle()).padding()
            NavigationLink(destination: NavigationLazyView(continueTo.init(
                channelId: channelId.trimmingCharacters(in: .whitespaces),
                proxyType: proxyType.agoraProxyType()
            )), label: {
                Text("Join Channel")
            }).disabled(channelId.isEmpty)
                .buttonStyle(.borderedProminent)
            Spacer()
            Text("Make sure you have enabled Cloud Proxy in Agora's Console")
                .font(.callout).foregroundColor(.accentColor).multilineTextAlignment(.center)
        }
    }
}

struct ProxyInputView_Previews: PreviewProvider {
    static var previews: some View {
        ProxyInputView(continueTo: CloudProxyView.self)
    }
}
