//
//  AgoraCanvasView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 22/03/2023.
//

import SwiftUI
import AgoraRtcKit

/// Extending AgoraRtcVideoCanvas so that it can remain the same between SwiftUI updates.
extension AgoraRtcVideoCanvas: ObservableObject {}

/**
AgoraVideoCanvasView is a UIViewRepresentable struct that provides a view for displaying remote or local video in an Agora RTC session.

Use AgoraVideoCanvasView to create a view that displays the video stream from a remote user or the local user's camera in an Agora RTC session. You can specify the render mode, crop area, and setup mode for the view.
*/
public struct AgoraVideoCanvasView: UIViewRepresentable {
    /// The `AgoraRtcVideoCanvas` object that represents the video canvas for the view.
    @StateObject var canvas = AgoraRtcVideoCanvas()

    /// A weak reference to the `AgoraRtcEngineKit` object for the session.
    public weak var agoraEngine: AgoraRtcEngineKit?
    /// The user ID of the remote user whose video to display, or `0` to display the local user's video.
    public let uid: UInt

    /**
     A UIViewRepresentable wrapper for an AgoraRtcVideoCanvas, which can be used to display a remote or local video stream in a SwiftUI view.

     - Parameters:
        - agoraEngine: An instance of the AgoraRtcEngineKit, which manages the video stream.
        - uid: The user ID for the video stream.

     - Returns: An AgoraVideoCanvasView instance, which can be added to a SwiftUI view hierarchy.
    */
    public init(agoraEngine: AgoraRtcEngineKit, uid: UInt) {
        self.agoraEngine = agoraEngine
        self.uid = uid
    }

    fileprivate init(uid: UInt) {
        self.uid = uid
    }
    /**
     Creates and configures a `UIView` for the view. This UIView will be the view the video is rendered onto.

     - Parameter context: The `UIViewRepresentable` context.

     - Returns: A `UIView` for displaying the video stream.
     */
    public func makeUIView(context: Context) -> UIView {
        setupCanvasView()
    }
    func setupCanvasView() -> UIView {
        // Create and return the remote video view
        let canvasView = UIView()
        canvas.view = canvasView
        canvas.uid = uid
        canvasView.isHidden = false
        if self.uid == 0 {
            // Start the local video preview
            agoraEngine?.startPreview()
            agoraEngine?.setupLocalVideo(canvas)
        } else {
            agoraEngine?.setupRemoteVideo(canvas)
        }
        return canvasView
    }
    /**
     Updates the Canvas view.
    */
    public func updateUIView(_ uiView: UIView, context: Context) {}
}

struct AgoraVideoCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        AgoraVideoCanvasView(uid: 0)
    }
}
