import Foundation
import AgoraRtcKit
import SwiftUI

private enum VirtualBackgroundType: String, Equatable, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case normal
    case blurred
    case color
    case image
}

#if os(macOS)
typealias UIColor = NSColor
#endif

private func convertColorToHex(_ color: UIColor) -> UInt {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    let redInt = UInt(red * 255)
    let greenInt = UInt(green * 255)
    let blueInt = UInt(blue * 255)

    let hexValue = (redInt << 16) | (greenInt << 8) | blueInt

    return hexValue
}

public class VirtualBackgroundManager: AgoraManager {
    @Published fileprivate var backgroundType: VirtualBackgroundType = .normal

    func updateBackground() {
        // First check that virtual backgrounds is available
        guard agoraEngine.isFeatureAvailable(
            onDevice: .videoPreprocessVirtualBackground
        ) else { return }

        switch backgroundType {
        case .normal: self.agoraEngine.enableVirtualBackground(false, backData: nil, segData: nil)
        case .blurred: self.blurBackground()
        case .color: self.colorBackground()
        case .image: self.imageBackground()
        }
    }

    func blurBackground() {
        let virtualBackgroundSource = AgoraVirtualBackgroundSource()
        virtualBackgroundSource.backgroundSourceType = .blur
        virtualBackgroundSource.blurDegree = .high

        let segData = AgoraSegmentationProperty()
        segData.modelType = .agoraAi

        agoraEngine.enableVirtualBackground(true, backData: virtualBackgroundSource, segData: segData)
    }

    func colorBackground() {
        let virtualBackgroundSource = AgoraVirtualBackgroundSource()
        virtualBackgroundSource.backgroundSourceType = .color
        virtualBackgroundSource.color = convertColorToHex(.red)

        let segData = AgoraSegmentationProperty()
        segData.modelType = .agoraAi

        agoraEngine.enableVirtualBackground(true, backData: virtualBackgroundSource, segData: segData)
    }

    func imageBackground() {
        let virtualBackgroundSource = AgoraVirtualBackgroundSource()
        virtualBackgroundSource.backgroundSourceType = .img
        virtualBackgroundSource.source = Bundle.main.path(forResource: "background_ss", ofType: "jpg")

        let segData = AgoraSegmentationProperty()
        segData.modelType = .agoraAi

        agoraEngine.enableVirtualBackground(true, backData: virtualBackgroundSource, segData: segData)
    }
}

/// A view that displays the video feeds of all participants in a channel.
public struct VirtualBackgroundView: View {
    @ObservedObject public var agoraManager = VirtualBackgroundManager(
        appId: DocsAppConfig.shared.appId, role: .broadcaster
    )

    var pickerBody: some View {
        Picker("Select Background Type", selection: $agoraManager.backgroundType) {
            ForEach(VirtualBackgroundType.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }.pickerStyle(SegmentedPickerStyle())
    }

    @State var virtualBackgroundsAvailable: Bool = false

    public var body: some View {
        ScrollView {
            VStack {
                ForEach(Array(agoraManager.allUsers), id: \.self) { uid in
                    AgoraVideoCanvasView(manager: agoraManager, uid: uid)
                        .aspectRatio(contentMode: .fit).cornerRadius(10)
                        .overlay(alignment: .bottom) {
                            if uid == agoraManager.localUserId {
                                if virtualBackgroundsAvailable {
                                    self.pickerBody.padding()
                                } else {
                                    Text("Virtual backgrounds not available")
                                }
                            }
                        }
                }
            }.padding(20)
        }.onAppear {
            await agoraManager.joinChannel(
                DocsAppConfig.shared.channel
            )
            DispatchQueue.main.async {
                self.virtualBackgroundsAvailable = agoraManager.agoraEngine.isFeatureAvailable(
                    onDevice: .videoPreprocessVirtualBackground
                )
            }
        }.onDisappear { agoraManager.leaveChannel()
        }.onChange(of: agoraManager.backgroundType) { _ in agoraManager.updateBackground() }
    }

    init(channelId: String) {
        DocsAppConfig.shared.channel = channelId
    }

    public static let docPath = getFolderName(from: #file)
    public static let docTitle = LocalizedStringKey("virtual-background-title")
}

struct VirtualBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        VirtualBackgroundView(channelId: "test")
    }
}
