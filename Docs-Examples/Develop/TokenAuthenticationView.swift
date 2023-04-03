//
//  TokenAuthenticationView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

/**
 A view that authenticates the user with a token and joins them to a channel using Agora SDK.
 */
struct TokenAuthenticationView: View {
    /// The Agora SDK manager.
    @ObservedObject var agoraManager = AgoraManager(appId: AppKeys.agoraKey, role: .broadcaster)
    /// The channel ID to join.
    public let channelId: String
    /// The URL of the token server.
    public let tokenUrl: String
    /// A flag indicating whether the token has been successfully fetched.
    @State public var tokenPassed: Bool?

    var body: some View {
        Group {
            if tokenPassed == nil {
                ProgressView()
            } else if tokenPassed == true {
                GettingStartedScrollView(users: agoraManager.allUsers, agoraKit: agoraManager.agoraKit)
            } else {
                Text("Error fetching token.")
            }
        }.onAppear {
            Task {
                // Fetch token from token server and join channel using Agora SDK.
                guard !channelId.isEmpty, let token = try? await fetchToken() else {
                    tokenPassed = false
                    return
                }
                tokenPassed = true
                agoraManager.agoraKit.joinChannel(byToken: token, channelId: channelId, info: nil, uid: 0)
            }
        }.onDisappear {
            agoraManager.leaveChannel()
        }
    }

    /**
     Initializes a new `TokenAuthenticationView`.

     - Parameter channelId: The channel ID to join.
     - Parameter tokenUrl: The URL of the token server.
     */
    public init(channelId: String, tokenUrl: String) {
        self.channelId = channelId
        self.tokenUrl = tokenUrl
    }

    /**
     A Codable struct representing the token server response.
     */
    public struct TokenResponse: Codable {
        public let rtcToken: String
    }

    /**
     Fetches the authentication token from the token server.

     - Returns: The authentication token, or `nil` if the token URL is empty or the token server request fails.
     */
    public func fetchToken() async throws -> String? {
        guard !tokenUrl.isEmpty else {
            return nil
        }
        guard let tokenServerURL = URL(
            string: "\(tokenUrl)/rtc/\(self.channelId)/\(AgoraClientRole.broadcaster.rawValue)/uid/0/"
        ) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: tokenServerURL)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.rtcToken
    }

}

struct TokenAuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        TokenAuthenticationView(channelId: "test", tokenUrl: "")
    }
}
