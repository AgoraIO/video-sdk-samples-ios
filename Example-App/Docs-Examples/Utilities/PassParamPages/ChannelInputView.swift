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
protocol ChannelOnlyNeeded: View {
    var channelId: String { get }
    init(channelId: String)
}

extension GettingStartedView: ChannelOnlyNeeded {}
extension CallQualityView: ChannelOnlyNeeded {}
extension ScreenShareAndVolumeView: ChannelOnlyNeeded {}

/**
 A view that takes a user inputted `channelId` string and navigates to a view that conforms to the `ChannelOnlyNeeded` protocol.

 The generic parameter `Content` specifies the type of view to navigate to, and must conform to the `ChannelOnlyNeeded` protocol.
 */
struct ChannelInputView<Content: ChannelOnlyNeeded>: View {
    /// The user inputted `channelId` string.
    @State var channelId: String = ""
    /// The type of view to navigate to.
    var continueTo: Content.Type

    var body: some View {
        VStack {
            TextField("Enter channel id", text: $channelId).padding()
            NavigationLink(destination: continueTo.init(
                channelId: channelId.trimmingCharacters(in: .whitespaces)
            ), label: {
                Text("Join Channel")
            }).disabled(channelId.isEmpty)
            .padding()
        }
    }
}

struct ChannelInputView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelInputView(continueTo: GettingStartedView.self)
    }
}
