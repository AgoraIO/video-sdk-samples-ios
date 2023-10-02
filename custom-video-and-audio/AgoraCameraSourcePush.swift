//
//  AgoraCameraSourcePush.swift
//  Docs-Examples
//
//  Created by Max Cobb on 23/06/2023.
//

#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import AgoraRtcKit

/// A delegate protocol for capturing frames from the camera source.
public protocol AgoraCameraSourcePushDelegate: AnyObject {
    /// Callback method called when a video frame is captured.
    ///
    /// - Parameters:
    ///   - capture: The AgoraCameraSourcePush instance that captured the frame.
    ///   - pixelBuffer: The pixel buffer of the captured video frame.
    ///   - rotation: The rotation angle of the captured video frame.
    ///   - timeStamp: The time stamp of the captured video frame.
    func myVideoCapture(
        _ pixelBuffer: CVPixelBuffer,
        rotation: Int, timeStamp: CMTime
    )

    /// The preview layer for displaying the captured video.
    var previewLayer: AVCaptureVideoPreviewLayer? { get set }
}

/// An open class that represents the camera source for pushing frames.
open class AgoraCameraSourcePush: NSObject {
    /// The delegate for the camera source.
    public var delegate: AgoraCameraSourcePushDelegate?

    /// The active capture session.
    private let captureSession: AVCaptureSession
    /// The dispatch queue for processing and sending images from the capture session.
    private let captureQueue: DispatchQueue
    /// The latest output from the active capture session.
    public var currentOutput: AVCaptureVideoDataOutput? {
        (self.captureSession.outputs as? [AVCaptureVideoDataOutput])?.first
    }

    /// Creates a new AgoraCameraSourcePush object.
    ///
    /// - Parameter delegate: The delegate to which the pixel buffer is sent.
    public init(delegate: AgoraCameraSourcePushDelegate) {
        self.delegate = delegate

        self.captureSession = AVCaptureSession()
        #if os(iOS)
        self.captureSession.usesApplicationAudioSession = false
        #endif

        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        if self.captureSession.canAddOutput(captureOutput) {
            self.captureSession.addOutput(captureOutput)
        }

        self.captureQueue = DispatchQueue(label: "AgoraCaptureQueue")

        delegate.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    }

    deinit {
        self.captureSession.stopRunning()
    }

    /// Starts capturing frames from the device.
    ///
    /// - Parameter device: The capture device from which to capture images.
    open func startCapture(ofDevice device: AVCaptureDevice) {
        guard let currentOutput = self.currentOutput else {
            return
        }

        currentOutput.setSampleBufferDelegate(self, queue: self.captureQueue)

        captureQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.setCaptureDevice(device, ofSession: strongSelf.captureSession)
            strongSelf.captureSession.beginConfiguration()
            if strongSelf.captureSession.canSetSessionPreset(.vga640x480) {
                strongSelf.captureSession.sessionPreset = .vga640x480
            }
            strongSelf.captureSession.commitConfiguration()
            strongSelf.captureSession.startRunning()
        }
    }

    /// Resumes capturing frames.
    func resumeCapture() {
        self.currentOutput?.setSampleBufferDelegate(self, queue: self.captureQueue)
        self.captureQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    /// Stops capturing frames.
    func stopCapture() {
        self.currentOutput?.setSampleBufferDelegate(nil, queue: nil)
        self.captureQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
}

public extension AgoraCameraSourcePush {
    /// Sets the capture device for the specified capture session.
    ///
    /// - Parameters:
    ///   - device: The capture device to set.
    ///   - captureSession: The capture session to which the device is added.
    func setCaptureDevice(_ device: AVCaptureDevice, ofSession captureSession: AVCaptureSession) {
        let currentInputs = captureSession.inputs as? [AVCaptureDeviceInput]
        let currentInput = currentInputs?.first

        if let currentInputName = currentInput?.device.localizedName,
            currentInputName == device.uniqueID {
            return
        }

        guard let newInput = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        captureSession.beginConfiguration()
        if let currentInput = currentInput {
            captureSession.removeInput(currentInput)
        }
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
        }
        captureSession.commitConfiguration()
    }
}

extension AgoraCameraSourcePush: AVCaptureVideoDataOutputSampleBufferDelegate {
    /// Called when a sample buffer is captured.
    ///
    /// - Parameters:
    ///   - output: The capture output.
    ///   - sampleBuffer: The captured sample buffer.
    ///   - connection: The connection from which the sample buffer is received.
    open func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        DispatchQueue.main.async { [weak self] in
            #if canImport(UIKit)
            let imgRot = UIDevice.current.orientation.intRotation
            #else
            let imgRot = 0
            #endif

            self?.delegate?.myVideoCapture(pixelBuffer, rotation: imgRot, timeStamp: time)
        }
    }
}

#if canImport(UIKit)
/// An extension of UIDeviceOrientation that provides utility methods for capturing video orientation.
internal extension UIDeviceOrientation {
    /// Converts the UIDeviceOrientation to AVCaptureVideoOrientation.
    ///
    /// - Returns: The corresponding AVCaptureVideoOrientation value.
    func toCaptureVideoOrientation() -> AVCaptureVideoOrientation {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return .portrait
        }
    }

    /// Converts the UIDeviceOrientation to an integer rotation value.
    ///
    /// - Returns: The corresponding rotation value in degrees.
    var intRotation: Int {
        switch self {
        case .portrait: return 90
        case .landscapeLeft: return 0
        case .landscapeRight: return 180
        case .portraitUpsideDown: return -90
        default: return 90
        }
    }
}
#endif
