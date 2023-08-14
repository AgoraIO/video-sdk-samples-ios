//
//  MultiChannelInputview.swift
//  Docs-Examples
//
//  Created by Max Cobb on 14/08/2023.
//

import SwiftUI

/// A protocol for views that require a `channelId` string as input.
protocol HasMultiChannelInput: HasDocPath {
    init(sourceChannel: String, destChannel: String)
}

extension ChannelRelayView: HasMultiChannelInput {}

/// A view that takes a user inputted `channelId` string and navigates to a view
/// which conforms to the `HasChannelInput` protocol.
///
/// The generic parameter `Content` specifies the type of view to navigate to,
/// and must conform to the `HasChannelInput` protocol.
struct MultiChannelInputView<Content: HasMultiChannelInput>: View {
    /// The user inputted `channelId` string.
    @State private var sourceChannel: String = DocsAppConfig.shared.channel
    /// The user inputted `channelId` string.
    @State private var destChannel: String = ""
    /// The type of view to navigate to.
    var continueTo: Content.Type

    var body: some View {
        VStack {
            TextField("Enter channel id", text: $sourceChannel).textFieldStyle(.roundedBorder).padding()
            NavigationLink(destination: NavigationLazyView(continueTo.init(
                sourceChannel: sourceChannel.trimmingCharacters(in: .whitespaces),
                destChannel: destChannel.trimmingCharacters(in: .whitespaces)
            ).navigationTitle(continueTo.docTitle).toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    GitHubButtonView(continueTo.docPath)
                }
            }), label: {
                Text("Join Channel")
            }).disabled(sourceChannel.isEmpty || destChannel.isEmpty)
                .buttonStyle(.borderedProminent)
                .navigationTitle("Channel Input")
        }
    }
}

struct MultiChannelInputview_Previews: PreviewProvider {
    static var previews: some View {
        MultiChannelInputView(continueTo: ChannelRelayView.self)
    }
}
