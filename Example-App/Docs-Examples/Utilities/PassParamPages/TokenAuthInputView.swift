//
//  TokenAuthInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI

/// A protocol for views that require a token server to fetch a token.
protocol HasTokenServerInput: View, HasDocPath {
    /// Initialiser for a new view that complies to ``HasTokenServerInput``
    /// - Parameters:
    ///   - channelId: The channel ID to join.
    ///   - tokenUrl: The URL for the token server
    init(channelId: String, tokenUrl: String)
}

extension TokenAuthenticationView: HasTokenServerInput {}

/// A view that allows the user to input a channel ID and a token URL,
/// and then navigates to a view that requires authentication.
///
/// The `TokenAuthInputView` takes a generic parameter `Content`
/// which conforms to the `HasTokenServerInput` protocol.
/// It shows two text fields for entering the channel ID and token URL, respectively,
/// and a navigation link that navigates to `Content` when the "Join Channel" button is pressed.
/// The navigation link is disabled if either field is empty.
///
/// After `TokenAuthInputView` is dismissed, the navigation stack returns to the previous view.
struct TokenAuthInputView<Content: HasTokenServerInput>: View {
    /// The channel ID entered by the user.
    @State var channelId: String = DocsAppConfig.shared.channel
    /// The token URL entered by the user.
    @State public var tokenUrl: String = DocsAppConfig.shared.tokenUrl
    /// The type of view to navigate to after the user inputs the channel ID and token URL.
    public var continueTo: Content.Type
    public var body: some View {
        VStack {
            TextField("Enter channel id", text: $channelId)
                .textFieldStyle(.roundedBorder).padding([.horizontal, .top])
            TextField("Enter token URL", text: $tokenUrl).keyboardType(.URL)
                .textFieldStyle(.roundedBorder).padding([.horizontal, .bottom])
            NavigationLink(destination: NavigationLazyView(continueTo.init(
                channelId: channelId.trimmingCharacters(in: .whitespaces),
                tokenUrl: tokenUrl.trimmingCharacters(in: .whitespaces)
            ).navigationTitle(continueTo.docTitle).toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    GitHubButtonView(continueTo.docPath)
                }
            }), label: {
                Text("Join Channel")
            }).disabled(channelId.isEmpty || tokenUrl.isEmpty)
                .buttonStyle(.borderedProminent)
                .navigationTitle("Token Authentication Input")
        }.onAppear {
            channelId = DocsAppConfig.shared.channel
        }
    }
}

struct TokenAuthInputView_Previews: PreviewProvider {
    static var previews: some View {
        TokenAuthInputView(continueTo: TokenAuthenticationView.self)
    }
}
