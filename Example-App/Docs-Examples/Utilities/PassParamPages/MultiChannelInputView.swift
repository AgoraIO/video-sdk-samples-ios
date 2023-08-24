//
//  MultiChannelInputview.swift
//  Docs-Examples
//
//  Created by Max Cobb on 14/08/2023.
//

import SwiftUI

/// A protocol for views that require a `channelId` string as input.
protocol HasMultiChannelInput: HasDocPath {
    init(primaryChannel: String, secondaryChannel: String, isRelay: Bool)
}

extension ChannelRelayView: HasMultiChannelInput {}

enum RelayStyle: String {
    case relay = "Channel Relay"
    case joinEx = "Join Multiple Channels"
}

/// A view that takes a user inputted `channelId` string and navigates to a view
/// which conforms to the `HasChannelInput` protocol.
///
/// The generic parameter `Content` specifies the type of view to navigate to,
/// and must conform to the `HasChannelInput` protocol.
struct MultiChannelInputView<Content: HasMultiChannelInput>: View {
    /// The user inputted primary channel ID.
    @State private var primaryChannel: String = DocsAppConfig.shared.channel
    /// The user inputted secondary channel ID.
    @State private var secondaryChannel: String = ""
    /// The type of view to navigate to.
    var continueTo: Content.Type

    @State private var relayType: RelayStyle = .joinEx

    var body: some View {
        VStack {
            TextField("Enter main channel", text: $primaryChannel).textFieldStyle(.roundedBorder).padding()
            TextField("Enter destination channel", text: $secondaryChannel).textFieldStyle(.roundedBorder).padding()
            /*
             Will re-add this section once tested more thoroughly.
            Picker("Multi-Channel Style", selection: $relayType) {
                ForEach([RelayStyle.joinEx, .relay], id: \.rawValue) {
                    Text($0.rawValue).tag($0)
                }
            }.pickerStyle(SegmentedPickerStyle())
             */
            NavigationLink(destination: NavigationLazyView(continueTo.init(
                primaryChannel: primaryChannel.trimmingCharacters(in: .whitespaces),
                secondaryChannel: secondaryChannel.trimmingCharacters(in: .whitespaces),
                isRelay: relayType == .relay
            ).navigationTitle(continueTo.docTitle).toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    GitHubButtonView(continueTo.docPath)
                }
            }), label: {
                Text(LocalizedStringKey("params-continue-button"))
            }).disabled(primaryChannel.isEmpty || secondaryChannel.isEmpty)
                .buttonStyle(.borderedProminent)
                .navigationTitle("Channel Input")
            if relayType == .relay {
                Spacer()
                Text("Make sure you have enabled Media Relay in Agora's Console.")
                    .font(.callout).foregroundColor(.accentColor).multilineTextAlignment(.center)
            }
        }
    }
}

struct MultiChannelInputview_Previews: PreviewProvider {
    static var previews: some View {
        MultiChannelInputView(continueTo: ChannelRelayView.self)
    }
}
