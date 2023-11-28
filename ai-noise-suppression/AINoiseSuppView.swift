import SwiftUI
import AgoraRtcKit

class NoiseSuppressionManager: AgoraManager {
    @discardableResult
    func setNoiseSuppression(_ enable: Bool, mode: AUDIO_AINS_MODE) -> Int32 {
        self.agoraEngine.setAINSMode(enable, mode: mode)
    }
}

enum AinsModes: String {
    case none
    case aggressive
    case balanced
    case ultraLowLatency
    var agoraCase: AUDIO_AINS_MODE? {
        switch self {
        case .none: nil
        case .aggressive: AUDIO_AINS_MODE.AINS_MODE_AGGRESSIVE
        case .balanced: AUDIO_AINS_MODE.AINS_MODE_BALANCED
        case .ultraLowLatency: AUDIO_AINS_MODE.AINS_MODE_ULTRALOWLATENCY
        }
    }
}

/// A view that encrypts your channel connection through Agora.
struct AINoiseSuppView: View {
    /// The Agora SDK manager.
    @ObservedObject var agoraManager = NoiseSuppressionManager(
        appId: DocsAppConfig.shared.appId, role: .broadcaster
    )
    @State var ainsMode: AinsModes = .none

    var body: some View {
        ZStack {
            VStack {
                self.basicScrollingVideos
                Picker("Choose Noise Suppression", selection: $ainsMode) {
                    ForEach([
                        AinsModes.none, .balanced, .aggressive, .ultraLowLatency
                    ], id: \.rawValue) { Text($0.rawValue).tag($0) }
                }.pickerStyle(SegmentedPickerStyle())
            }.onChange(of: ainsMode) { newValue in
                if let agoraCase = newValue.agoraCase {
                    self.agoraManager.setNoiseSuppression(true, mode: agoraCase)
                } else {
                    self.agoraManager.setNoiseSuppression(false, mode: .AINS_MODE_BALANCED)
                }
            }
            ToastView(message: $agoraManager.label)
        }.onAppear {
            await agoraManager.joinChannel(DocsAppConfig.shared.channel)
        }.onDisappear { agoraManager.leaveChannel() }
    }

    /// Initializes a new `MediaEncryptionView`.
    ///
    /// - Parameters:
    ///   - channelId: The channel ID to join.
    public init(channelId: String) {
        DocsAppConfig.shared.channel = channelId
    }
    static let docPath = getFolderName(from: #file)
    static let docTitle = LocalizedStringKey("ai-noise-suppression-title")
}

#Preview {
    AINoiseSuppView(channelId: "test")
}
