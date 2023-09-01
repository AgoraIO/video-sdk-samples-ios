//
//  AgoraCustomVideoCanvasView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 23/06/2023.
//

import SwiftUI
import AVKit
import AgoraRtcKit

#if os(iOS)
/// SwiftUI representable for a ``CustomVideoSourcePreview``.
public struct AgoraCustomVideoCanvasView: UIViewRepresentable {
    /// The `AgoraRtcVideoCanvas` object that represents the video canvas for the view.
    @StateObject var canvas = CustomVideoSourcePreview()

    /// Preview layer where the camera frames come into
    var previewLayer: AVCaptureVideoPreviewLayer?

    /// Creates and configures a `UIView` for the view. This UIView will be the view the video is rendered onto.
    /// - Parameter context: The `UIViewRepresentable` context.
    /// - Returns: A `UIView` for displaying the custom local video stream.
    public func makeUIView(context: Context) -> UIView { setupCanvasView() }
    func setupCanvasView() -> UIView { canvas }

    /// Updates the `AgoraRtcVideoCanvas` object for the view with new values, if necessary.
    func updateCanvasValues() {
        if self.previewLayer != canvas.previewLayer, let previewLayer {
            canvas.insertCaptureVideoPreviewLayer(previewLayer: previewLayer)
        }
    }

    /// Updates the Canvas view.
    public func updateUIView(_ uiView: UIView, context: Context) {
        self.updateCanvasValues()
    }
}
/// View to show the custom camera feed for the local camera feed.
open class CustomVideoSourcePreview: UIView, ObservableObject {
    /// Layer that displays video from a camera device.
    open private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    /// Add new frame to the preview layer
    /// - Parameter previewLayer: New `previewLayer` to be displayed on the preview.
    open func insertCaptureVideoPreviewLayer(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer?.removeFromSuperlayer()
        previewLayer.frame = bounds
        layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }

    /// Tells the delegate a layer's bounds have changed.
    /// - Parameter layer: The layer that requires layout of its sublayers.
    override open func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        previewLayer?.frame = bounds
        if let connection = self.previewLayer?.connection {
            let currentDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection: AVCaptureConnection = connection

            if previewLayerConnection.isVideoOrientationSupported {
                self.updatePreviewLayer(
                    layer: previewLayerConnection,
                    orientation: orientation.toCaptureVideoOrientation()
                )
            }
        }
    }

    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        self.previewLayer?.frame = self.bounds
    }
}
#elseif os(macOS)
/// SwiftUI representable for a ``CustomVideoSourcePreview``.
public struct AgoraCustomVideoCanvasView: NSViewRepresentable {
    /// The `AgoraRtcVideoCanvas` object that represents the video canvas for the view.
    @StateObject var canvas = CustomVideoSourcePreview()

    /// Preview layer where the camera frames come into
    var previewLayer: AVCaptureVideoPreviewLayer?

    /// Creates and configures an `NSView` for the view. This NSView will be the view the video is rendered onto.
    /// - Parameter context: The `NSViewRepresentable` context.
    /// - Returns: A `NSView` for displaying the custom local video stream.
    public func makeNSView(context: Context) -> NSView { setupCanvasView() }
    func setupCanvasView() -> NSView { canvas }

    /// Updates the `AgoraRtcVideoCanvas` object for the view with new values, if necessary.
    func updateCanvasValues() {
        if self.previewLayer != canvas.previewLayer, let previewLayer {
            canvas.insertCaptureVideoPreviewLayer(previewLayer: previewLayer)
        }
    }

    /// Updates the Canvas view.
    public func updateNSView(_ uiView: NSView, context: Context) {
        self.updateCanvasValues()
    }
}
/// View to show the custom camera feed for the local camera feed.
open class CustomVideoSourcePreview: NSView, ObservableObject {
    /// Layer that displays video from a camera device.
    open private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    /// Add new frame to the preview layer
    /// - Parameter previewLayer: New `previewLayer` to be displayed on the preview.
    open func insertCaptureVideoPreviewLayer(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer?.removeFromSuperlayer()
        previewLayer.frame = bounds
        layer?.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }
}
#endif
