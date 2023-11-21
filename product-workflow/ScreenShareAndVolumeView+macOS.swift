//
//  ScreenShareAndVolumeView+macOS.swift
//  Docs-Examples
//
//  Created by Max Cobb on 21/11/2023.
//

import AgoraRtcKit
import CoreGraphics
import SwiftUI

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

    func startScreenshare(with source: AgoraScreenCaptureSourceInfo) {
        self.screenSharingActive = true
        self.agoraManager.startScreenShare(with: source.sourceId, isDisplay: source.sourceName.contains("Screens"))
    }
    func stopScreenshare() {
        self.screenSharingActive = false
        self.agoraManager.stopScreenShare()
    }
}

struct ScreenShareModal: View {

    @Binding var displayed: Bool
    @State var screens: [String: [AgoraScreenCaptureSourceInfo]]
    @State var selectedScreen: AgoraScreenCaptureSourceInfo?
    @State var selectedGroup: String = ""
    var startScreenShare: (AgoraScreenCaptureSourceInfo) -> Void
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                LazyHGrid(rows: [GridItem(.flexible())]) {
                    ForEach(
                        screens.keys.sorted(), id: \.self
                    ) { name in
                        if let screenSources = screens[name] {
                            ScreenGroupButton(
                                selectedScreen: $selectedScreen,
                                screenSources: screenSources,
                                groupName: name,
                                selectedGroup: $selectedGroup
                            )
                        }
                    }
                }.padding()
            }.frame(height: 75)
            if let selectedScreens = screens[selectedGroup] {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(selectedScreens, id: \.sourceId) { screen in
                            Button(action: {
                                self.selectedScreen = screen
                            }, label: {
                                Image(nsImage: screen.thumbImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 90, height: 90) // Adjust size as needed
                            }).background(
                                selectedScreen?.sourceId == screen.sourceId ?
                                Color.green : Color.secondary
                            )
                        }
                    }.padding()
                }
            } else {
                Spacer()
            }
            Button(action: {
                guard let selectedScreen else { return }
                self.displayed = false
                self.startScreenShare(selectedScreen)
            }, label: {
                Text("Start Screenshare")
            }).disabled(selectedScreen == nil).padding()

        }.onAppear {
            self.selectedGroup = screens.keys.sorted().first ?? ""
        }
    }
}

struct ScreenGroupButton: View {
    @Binding var selectedScreen: AgoraScreenCaptureSourceInfo?
    @State var screenSources: [AgoraScreenCaptureSourceInfo]
    @State var groupName: String
    @Binding var selectedGroup: String
    var body: some View {
        Button(action: {
            selectedScreen = nil
            selectedGroup = groupName
        }, label: {
            VStack {
                if let firstScreen = screenSources.first,
                   let appIcon = firstScreen.iconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                } else {
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                }
                Text(groupName.replacingOccurrences(of: "00", with: ""))
            }.buttonStyle(NoHighlightButtonStyle())
                .foregroundStyle(
                    selectedGroup == groupName ?
                        Color.green : Color.secondary
                ).padding(3)
        })

    }
}

struct NoHighlightButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .focusable(false)
    }
}

#endif
