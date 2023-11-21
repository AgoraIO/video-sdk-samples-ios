//
//  ScreenShareAndVolumeView+macOS.swift
//  Docs-Examples
//
//  Created by Max Cobb on 21/11/2023.
//

import AgoraRtcKit
import CoreGraphics

#if os(macOS)
extension ScreenShareVolumeManager {
    func getScreensAndWindows() -> [AgoraScreenCaptureSourceInfo]? {
        agoraEngine.getScreenCaptureSources(
            withThumbSize: .zero,
            iconSize: .zero,
            includeScreen: true
        )
    }

    func startScreenShare(displayId: CGWindowID) {
        let params = AgoraScreenCaptureParameters()
        params.dimensions = AgoraVideoDimension1920x1080
        params.frameRate = AgoraVideoFrameRate.fps15.rawValue
        self.agoraEngine.startScreenCapture(
            byDisplayId: displayId, regionRect: .zero,
            captureParams: params
        )
    }

    func startScreenShare(windowId: CGWindowID) {
        let params = AgoraScreenCaptureParameters()
        params.dimensions = AgoraVideoDimension1920x1080
        params.frameRate = AgoraVideoFrameRate.fps15.rawValue
        self.agoraEngine.startScreenCapture(
            byWindowId: windowId, regionRect: .zero,
            captureParams: params
        )
    }

    func stopScreenShare() {
        self.agoraEngine.stopScreenCapture()
    }

    public func rtcEngine(
        _ engine: AgoraRtcEngineKit, localVideoStateChangedOf state: AgoraVideoLocalState,
        error: AgoraLocalVideoStreamError, sourceType: AgoraVideoSourceType
    ) {
        if sourceType == .screen {
            let newChannelOpt = AgoraRtcChannelMediaOptions()
            switch state {
            case .capturing:
                newChannelOpt.publishScreenTrack = true
                newChannelOpt.publishCameraTrack = false
            case .stopped, .failed:
                newChannelOpt.publishScreenTrack = false
                newChannelOpt.publishCameraTrack = true
            default: return
            }
            agoraEngine.updateChannel(with: newChannelOpt)
        }
    }

    func startScreenShare(with id: CGWindowID, isDisplay: Bool) {
        if isDisplay {
            self.startScreenShare(displayId: id)
        } else {
            self.startScreenShare(windowId: id)
        }
    }
}

extension ScreenShareAndVolumeView {
    func showScreenshareModal() {
        if let screensAndWindows = self.agoraManager.getScreensAndWindows() {
            screensAndWindows.forEach { item in
                if item.sourceName.contains("screen-") {
                    item.sourceName = "00Screens"
                }
            }
            self.agoraManager.groupedScreens = Dictionary(
                grouping: screensAndWindows, by: { $0.sourceName }
            )
        }
        if let mainWindow = NSApp.mainWindow {
            let windowFrame = mainWindow.frame
            self.popupWidth = windowFrame.width - 50
            self.popupHeight = windowFrame.height - 50
        }
        self.showPopup = true
    }

    @State private var popupWidth: CGFloat = 0
    @State private var popupHeight: CGFloat = 0

    func startScreenshare(with source: AgoraScreenCaptureSourceInfo) {
        self.screenSharingActive = true
        self.agoraManager.startScreenShare(with: source.sourceId, isDisplay: source.sourceName.contains("Screens"))
    }
    func stopScreenshare() {
        self.screenSharingActive = false
        self.agoraManager.stopScreenShare()
    }
}
#endif
