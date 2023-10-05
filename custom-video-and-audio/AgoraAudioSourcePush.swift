//
//  AgoraCameraSourcePush.swift
//  Docs-Examples
//
//  Created by Max Cobb on 04/10/2023.
//

#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import AgoraRtcKit

class AgoraAudioSourcePush: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {

    private var captureSession: AVCaptureSession?
    private var audioOutput: AVCaptureAudioDataOutput?

    var onAudioFrameCaptured: ((CMSampleBuffer) -> Void)

    init(audioDevice: AVCaptureDevice, onAudioFrameCaptured: @escaping ((CMSampleBuffer) -> Void)) {
        self.onAudioFrameCaptured = onAudioFrameCaptured
        super.init()
        setupCaptureSession(audioDevice: audioDevice)
    }

    deinit {
        self.captureSession?.stopRunning()
    }

    private func setupCaptureSession(audioDevice: AVCaptureDevice) {
        captureSession = AVCaptureSession()

        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession!.canAddInput(audioInput) {
                captureSession!.addInput(audioInput)
            }

            audioOutput = AVCaptureAudioDataOutput()
            let audioQueue = DispatchQueue(label: "AudioQueue")
            audioOutput!.setSampleBufferDelegate(self, queue: audioQueue)

            if captureSession!.canAddOutput(audioOutput!) {
                captureSession!.addOutput(audioOutput!)
            }

        } catch {
            print("Error setting up audio capture: \(error)")
        }
    }

    func startCapturing() {
        captureSession?.startRunning()
    }

    func stopCapturing() {
        self.audioOutput?.setSampleBufferDelegate(nil, queue: nil)
        self.captureSession?.stopRunning()
    }

    func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        self.onAudioFrameCaptured(sampleBuffer)
    }
}
