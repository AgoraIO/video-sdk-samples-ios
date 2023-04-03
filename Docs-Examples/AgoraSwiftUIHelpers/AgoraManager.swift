//
//  AgoraManager.swift
//  Docs-Examples
//
//  Created by Max Cobb on 03/04/2023.
//

import AgoraRtcKit

/**
``AgoraManager`` is a class that provides an interface to the Agora RTC Engine Kit. It conforms to the `ObservableObject` and `AgoraRtcEngineDelegate` protocols.

Use AgoraManager to set up and manage Agora RTC sessions, manage the client's role, and control the client's connection to the Agora RTC server.
*/
open class AgoraManager: NSObject, ObservableObject, AgoraRtcEngineDelegate {
    /// The Agora App ID for the session.
    public let appId: String
    /// The client's role in the session.
    public var role: AgoraClientRole = .audience {
        didSet { agoraKit.setClientRole(role) }
    }
    /// The Agora RTC Engine Kit for the session.
    public var agoraKit: AgoraRtcEngineKit {
        let eng = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
        eng.enableVideo()
        eng.setClientRole(role)
        return eng
    }

    /// The set of all users in the channel.
    @Published public var allUsers: Set<UInt> = []

    /**
     Initializes a new instance of `AgoraManager` with the specified app ID and client role.

     - Parameters:
       - appId: The Agora App ID for the session.
       - role: The client's role in the session. The default value is `.audience`.
     */
    public init(appId: String, role: AgoraClientRole = .audience) {
        self.appId = appId
        self.role = role
    }

    /**
     Leaves the channel and stops the preview for the session.

     - Parameter leaveChannelBlock: An optional closure that will be called when the client leaves the channel. The closure takes an `AgoraChannelStats` object as its parameter.

     This method also empties all entries in ``allUsers``
     */
    open func leaveChannel(leaveChannelBlock: ((AgoraChannelStats) -> Void)? = nil) {
        self.agoraKit.leaveChannel(leaveChannelBlock)
        self.agoraKit.stopPreview()
        AgoraRtcEngineKit.destroy()
        self.allUsers.removeAll()
    }

    /**
     Tells the delegate that the user has successfully joined the channel.
     - Parameters:
        - engine: The Agora RTC engine kit object.
        - channel: The channel name.
        - uid: The ID of the user joining the channel.
        - elapsed: The time elapsed (ms) from the user calling `joinChannel` until this method is called.

     If the client's role is `.broadcaster`, this method also adds the broadcaster to the `allUsers` set.
     */
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        if self.role == .broadcaster { self.allUsers.insert(0) }
    }

    /**
     Tells the delegate that a remote user has joined the channel.

     - Parameters:
        - engine: The Agora RTC engine kit object.
        - uid: The ID of the user joining the channel.
        - elapsed: The time elapsed (ms) from the user calling `joinChannel` until this method is called.

     This method adds the remote user to the `allUsers` set.
     */
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        self.allUsers.insert(uid)
    }
    /**
     Tells the delegate that a remote user has left the channel.

     - Parameters:
         - engine: The Agora RTC engine kit object.
         - uid: The ID of the user who left the channel.
         - reason: The reason why the user left the channel.

     This method removes the remote user from the `allUsers` set.
     */
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        self.allUsers.remove(uid)
    }
}
