import SwiftUI
import AgoraRtcKit

class AudioVoiceEffectsManager: AgoraManager {

    var audioEffectId: Int32 = .random(in: 1000...10_000)

    override func setupEngine() -> AgoraRtcEngineKit {
        let eng = super.setupEngine()
        eng.setAudioProfile(.musicHighQualityStereo)
        eng.setAudioScenario(.gameStreaming)
        return eng
    }

    func preloadEffect(soundEffectId: Int32, effectFilePath: String) {
        // Pre-load sound effects to improve performance
        agoraEngine.preloadEffect(soundEffectId, filePath: effectFilePath)
    }

    func startMixing(audioFilePath: String, loopBack: Bool, cycle: Int, startPos: Int) {
        agoraEngine.startAudioMixing(
            audioFilePath, loopback: loopBack,
            cycle: cycle, startPos: startPos
        )
    }

    func stopMixing() {
        agoraEngine.stopAudioMixing()
    }

    func playEffect(soundEffectId: Int32, effectFilePath: String) {
        agoraEngine.playEffect(
            soundEffectId,            // The ID of the sound effect file.
            filePath: effectFilePath, // The path of the sound effect file.
            loopCount: 0,
            pitch: 1.0,               // The pitch of the audio effect. 1 = original pitch.
            pan: 0.0,                 // The spatial position of the audio effect (-1 to 1)
            gain: 100,                // The volume of the audio effect. 100 = original volume.
            publish: true,            // Whether to publish the audio effect to remote users.
            startPos: 0               // The playback starting position (in ms).
        )
    }

    func pauseEffect(soundEffectId: Int32) {
        agoraEngine.pauseEffect(soundEffectId)
    }

    func resumeEffect(soundEffectId: Int32) {
        agoraEngine.resumeEffect(soundEffectId)
    }

    func stopEffect(soundEffectId: Int32) {
        agoraEngine.stopEffect(soundEffectId)
    }

    func applyVoiceBeautifierPreset(beautifier: AgoraVoiceBeautifierPreset) {
        // Use a preset value from Constants. For example, Constants.CHAT_BEAUTIFIER_MAGNETIC
        agoraEngine.setVoiceBeautifierPreset(beautifier)
    }

    func applyAudioEffectPreset(preset: AgoraAudioEffectPreset) {
        // Use a preset value from Constants. For example, Constants.VOICE_CHANGER_EFFECT_HULK
        agoraEngine.setAudioEffectPreset(preset)
    }

    func applyVoiceConversionPreset(preset: AgoraVoiceConversionPreset) {
        // Use a preset value from Constants. For example, Constants.VOICE_CHANGER_CARTOON
        agoraEngine.setVoiceConversionPreset(preset)
    }

    func applyLocalVoiceFormant(preset: Double) {
        // The value range is [-1.0, 1.0]. The default value is 0.0,
        agoraEngine.setLocalVoiceFormant(preset)
    }

    func setVoiceEqualization(bandFrequency: AgoraAudioEqualizationBandFrequency, bandGain: Int) {
        // Set local voice equalization.
        // The first parameter sets the band frequency. Ranges from 0 to 9.
        // Each value represents the center frequency of the band:
        //      31, 62, 125, 250, 500, 1k, 2k, 4k, 8k, and 16k Hz.
        // The second parameter sets the gain of each band. Ranges from -15 to 15 dB.
        //      The default value is 0.
        agoraEngine.setLocalVoiceEqualizationOf(bandFrequency, withGain: bandGain)
    }

    func setVoicePitch(value: Double) {
        //  The value range is [0.5,2.0] default value is 1.0
        agoraEngine.setLocalVoicePitch(value)
    }

    func rtcEngineDidAudioEffectFinish(_ engine: AgoraRtcEngineKit, soundId: Int32) {
        // Occurs when the audio effect playback finishes.
    }

    func setAudioRoute(enableSpeakerPhone: Bool) {
        // Disable the default audio route
        agoraEngine.setDefaultAudioRouteToSpeakerphone(false)
        // Enable or disable the speakerphone temporarily
        agoraEngine.setEnableSpeakerphone(enableSpeakerPhone)
    }

    @Published var audioEffect: AudioEffect = .none
    @Published var speakerOn: Bool = false
}

internal enum AudioEffect: String, CaseIterable {
    case none
    case beautify
    case highPitch
    case cartoon
}

/// A view that authenticates the user with a token and joins them to a channel using Agora SDK.
struct AudioVoiceEffectsView: View {
    /// The Agora SDK manager.
    @ObservedObject var agoraManager: AudioVoiceEffectsManager

    var body: some View {
        ZStack {
            VStack {
                self.basicScrollingVideos
                self.voiceEffectButtons
            }
            ToastView(message: $agoraManager.label)
        }.onAppear { await agoraManager.joinChannel(DocsAppConfig.shared.channel)
        }.onDisappear { agoraManager.leaveChannel() }
    }

    var voiceEffectButtons: some View {
        HStack {
            Picker("Choose Audio Effect", selection: $agoraManager.audioEffect) {
                ForEach(
                    [AudioEffect.none, .beautify, .highPitch, .cartoon], id: \.rawValue
                ) { Text($0.rawValue).tag($0) }
            }.pickerStyle(SegmentedPickerStyle())
            Toggle(isOn: $agoraManager.speakerOn) {
                Image(systemName: "speaker.\(agoraManager.speakerOn ? "wave.3" : "slash")")
            }.frame(maxWidth: 100)
        }
         .onChange(of: agoraManager.audioEffect) { newValue in
//             agoraManager.stopEffect(soundEffectId: agoraManager.audioEffectId)
//             agoraManager.stopMixing()
//             agoraManager.applyAudioEffectPreset(preset: .off)
             agoraManager.applyVoiceBeautifierPreset(beautifier: .presetOff)
             agoraManager.applyVoiceConversionPreset(preset: .off)
             agoraManager.setVoicePitch(value: 1)
             switch newValue {
             case .none: break
             case .beautify:
                 agoraManager.applyVoiceBeautifierPreset(beautifier: .presetChatBeautifierFresh)
             case .highPitch: agoraManager.setVoicePitch(value: 2)
             case .cartoon: agoraManager.applyVoiceConversionPreset(preset: .changerCartoon)
             }
         }.onChange(of: agoraManager.speakerOn) { newValue in
             agoraManager.setAudioRoute(enableSpeakerPhone: newValue)
         }
    }

    /// Initializes a new ``GeofencingView``.
    ///
    /// - Parameters:
    ///   - channelId: The channel ID to join.
    public init(channelId: String) {
        DocsAppConfig.shared.channel = channelId
        agoraManager = AudioVoiceEffectsManager(
            appId: DocsAppConfig.shared.appId,
            role: .broadcaster
        )
    }

    static let docPath = getFolderName(from: #file)
    static let docTitle = LocalizedStringKey("audio-and-voice-effects-title")
}
