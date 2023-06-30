//
//  ChannelInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI

/**
 A protocol for views that require a `channelId` string as input.
 */
protocol HasChannelInput: View {
    var channelId: String { get }
    init(channelId: String)
}

extension GettingStartedView: HasChannelInput {}
extension CallQualityView: HasChannelInput {}
extension ScreenShareAndVolumeView: HasChannelInput {}

/**
 A view that takes a user inputted `channelId` string and navigates to a view that conforms to the `HasChannelInput` protocol.

 The generic parameter `Content` specifies the type of view to navigate to, and must conform to the `HasChannelInput` protocol.
 */
struct ChannelInputView<Content: HasChannelInput>: View {
    /// The user inputted `channelId` string.
    @State var channelId: String = DocsAppConfig.shared.channel
    /// The type of view to navigate to.
    var continueTo: Content.Type

    var body: some View {
        VStack {
            TextField("Enter channel id", text: $channelId).textFieldStyle(.roundedBorder).padding()
            NavigationLink(destination: continueTo.init(
                channelId: channelId.trimmingCharacters(in: .whitespaces)
            ), label: {
                Text("Join Channel")
            }).disabled(channelId.isEmpty)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct ChannelInputView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelInputView(continueTo: GettingStartedView.self)
    }
}
