//
//  ChannelInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI

protocol HasDocPath: View {
    static var docPath: String { get }
    static var docTitle: LocalizedStringKey { get }
}

/// A protocol for views that require a `channelId` string as input.
protocol HasChannelInput: HasDocPath {
    init(channelId: String)
}

extension GettingStartedView: HasChannelInput {}
extension CallQualityView: HasChannelInput {}
extension ScreenShareAndVolumeView: HasChannelInput {}
extension RawMediaProcessingView: HasChannelInput {}
extension VirtualBackgroundView: HasChannelInput {}

/// A view that takes a user inputted `channelId` string and navigates to a view
/// which conforms to the `HasChannelInput` protocol.
///
/// The generic parameter `Content` specifies the type of view to navigate to,
/// and must conform to the `HasChannelInput` protocol.
struct ChannelInputView<Content: HasChannelInput>: View {
    /// The user inputted `channelId` string.
    @State var channelId: String = DocsAppConfig.shared.channel
    /// The type of view to navigate to.
    var continueTo: Content.Type

    var body: some View {
        VStack {
            TextField("Enter channel id", text: $channelId).textFieldStyle(.roundedBorder).padding()
            NavigationLink(destination: NavigationLazyView(continueTo.init(
                channelId: channelId.trimmingCharacters(in: .whitespaces)
            ).navigationTitle(continueTo.docTitle).toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    GitHubButtonView(continueTo.docPath)
                }
                #endif
            }), label: {
                Text(LocalizedStringKey("params-continue-button"))
            }).disabled(channelId.isEmpty)
                .buttonStyle(.borderedProminent)
                .navigationTitle("Channel Input")
        }.onAppear {
            channelId = DocsAppConfig.shared.channel
        }
    }
}

struct ChannelInputView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelInputView(continueTo: GettingStartedView.self)
    }
}
