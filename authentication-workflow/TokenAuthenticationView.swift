//
//  TokenAuthenticationView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import SwiftUI
import AgoraRtcKit

/**
 * Fetches a token from the specified token server URL.
 *
 * - Parameters:
 *     - tokenUrl: The URL of the token server.
 *     - channel: The name of the channel for which the token will be used.
 *     - role: The role of the user for which the token will be generated.
 *     - userId: The ID of the user for which the token will be generated. Defaults to 0.
 *
 * - Returns: An optional string containing the RTC token, or `nil` if an error occurred.
 *
 * - Throws: An error of type `Error` if an error occurred during the token fetching process.
 */
public func fetchToken(
    from tokenUrl: String, channel: String,
    role: AgoraClientRole, userId: UInt = 0
) async throws -> String? {
    guard !tokenUrl.isEmpty else {
        return nil
    }
    guard let tokenServerURL = URL(
        string: "\(tokenUrl)/rtc/\(channel)/\(role.rawValue)/uid/\(userId)/"
    ) else { return nil }
    let (data, _) = try await URLSession.shared.data(from: tokenServerURL)
    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
    return tokenResponse.rtcToken
}

/**
 * A Codable struct representing the token server response.
 */
public struct TokenResponse: Codable {
    /// Value of the RTC Token.
    public let rtcToken: String
}

/**
 * A view that authenticates the user with a token and joins them to a channel using Agora SDK.
 */
struct TokenAuthenticationView: View {

    /**
     * Fetch a token from the token server, and then join the channel using Agora SDK
     * - Returns: A boolean, for whether or not the token fetching was successful.
     */
    func fetchTokenThenJoin() async -> Bool {
        if !channelId.isEmpty,
           let token = try? await fetchToken(
            from: self.tokenUrl, channel: self.channelId,
            role: agoraManager.role, userId: 0
        ) {
            agoraManager.joinChannel(channelId, token: token)
            return true
        } else {
            return false
        }
    }

    /// The Agora SDK manager.
    @ObservedObject var agoraManager = AgoraManager(appId: DocsAppConfig.shared.appId, role: .broadcaster)
    /// The channel ID to join.
    public let channelId: String
    /// The URL of the token server.
    public let tokenUrl: String
    /// A flag indicating whether the token has been successfully fetched.
    @State public var tokenPassed: Bool?

    /**
     * Initializes a new `TokenAuthenticationView`.
     *
     * - Parameter channelId: The channel ID to join.
     * - Parameter tokenUrl: The URL of the token server.
     */
    public init(channelId: String, tokenUrl: String) {
        self.channelId = channelId
        self.tokenUrl = tokenUrl
    }

    var body: some View {
        Group {
            if tokenPassed == nil {
                ProgressView()
            } else if tokenPassed == true {
                ScrollView {
                    VStack {
                        ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                            AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                                .aspectRatio(contentMode: .fit).cornerRadius(10)
                        }
                    }.padding(20)
                }
            } else {
                Text("Error fetching token.")
            }
        }.onAppear {
            /// On joining, call ``TokenAuthenticationView/fetchTokenThenJoin()``.
            Task { tokenPassed = await fetchTokenThenJoin() }
        }.onDisappear { agoraManager.leaveChannel() }
    }
}

struct TokenAuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        TokenAuthenticationView(channelId: "test", tokenUrl: "")
    }
}
