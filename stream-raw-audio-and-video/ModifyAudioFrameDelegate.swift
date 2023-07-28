import AgoraRtcKit
import Accelerate

protocol HasModifyAudio {
    var audioModification: AudioModification { get }
}

public class ModifyAudioFrameDelegate: NSObject, AgoraAudioFrameDelegate {

    var modifyController: any HasModifyAudio

    public func onRecordAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        switch modifyController.audioModification {
        case .louder: applyAudioVolumeModification(frame, gain: 4)
        case .reverb: applyReverbAudioModification(frame)
        case .none: break
        }
        return true
    }

    init(modifyController: any HasModifyAudio) {
        self.modifyController = modifyController
    }
}

// MARK: - Audio Buffer Modifiers

public extension ModifyAudioFrameDelegate {
    private func applyAudioVolumeModification(_ frame: AgoraAudioFrame, gain: Float) {
        // Implement high audio modification here.
        // You can manipulate the audio data in the `frame` parameter to apply high modification.
        // For example, you can increase volume, apply audio effects, etc.
        // Note: Be cautious with high modifications as it may affect the audio quality or introduce distortion.

        // Example: Increase audio volume by multiplying each audio sample with a gain factor.
        if let buffer = frame.buffer {
            let bytesPerSample = frame.bytesPerSample

            // The buffer contains audio samples in an interleaved format.
            // The number of audio samples is frame.samplesPerChannel * frame.channels.
            let totalSamples = frame.samplesPerChannel * frame.channels

            // Loop through each audio sample in the buffer and apply the gain.
            switch bytesPerSample {
            case 2: // Int16 format (16-bit signed integer)
                let int16Buffer = buffer.bindMemory(to: Int16.self, capacity: totalSamples)
                for i in 0..<totalSamples {
                    int16Buffer[i] = Int16(Float(int16Buffer[i]) * gain)
                }
            case 4: // Float32 format (32-bit floating-point)
                let floatBuffer = buffer.bindMemory(to: Float.self, capacity: totalSamples)
                for i in 0..<totalSamples {
                    floatBuffer[i] *= gain
                }

            default:
                print("Unsupported bytesPerSample format: \(bytesPerSample)")
            }
        }
    }

    private func applyReverbAudioModification(_ frame: AgoraAudioFrame) {
        // Define reverb parameters
        let numEchoes = 4
        let delayTimes: [Int] = [1000, 1500, 2000, 2500] // Delay times in samples (adjust as needed)
        let gainFactors: [Float] = [0.5, 0.4, 0.3, 0.2] // Adjust gain factors for each echo

        if let buffer = frame.buffer {
            let bytesPerSample = frame.bytesPerSample
            let totalSamples = frame.samplesPerChannel * frame.channels

            switch bytesPerSample {
            case 2: // Int16 format (16-bit signed integer)
                let int16Buffer = buffer.bindMemory(to: Int16.self, capacity: totalSamples)

                // Create delayed echoes and add to the original audio
                for i in 0..<totalSamples {
                    var echoSample: Float = 0.0
                    for echoIndex in 0..<numEchoes {
                        let delaySampleIndex = i - delayTimes[echoIndex]
                        if delaySampleIndex >= 0 && delaySampleIndex < totalSamples {
                            echoSample += Float(int16Buffer[delaySampleIndex]) * gainFactors[echoIndex]
                        }
                    }

                    let originalSample = Float(int16Buffer[i])
                    let reverbSample = originalSample + echoSample

                    // Clip the reverb sample to avoid clipping and distortion
                    let clampedSample = max(min(reverbSample, Float(Int16.max)), Float(Int16.min))
                    int16Buffer[i] = Int16(clampedSample)
                }

            case 4: // Float32 format (32-bit floating-point)
                let floatBuffer = buffer.bindMemory(to: Float.self, capacity: totalSamples)

                // Create delayed echoes and add to the original audio
                for i in 0..<totalSamples {
                    var echoSample: Float = 0.0
                    for echoIndex in 0..<numEchoes {
                        let delaySampleIndex = i - delayTimes[echoIndex]
                        if delaySampleIndex >= 0 && delaySampleIndex < totalSamples {
                            echoSample += floatBuffer[delaySampleIndex] * gainFactors[echoIndex]
                        }
                    }

                    let originalSample = floatBuffer[i]
                    let reverbSample = originalSample + echoSample

                    // Clip the reverb sample to avoid clipping and distortion
                    let clampedSample = max(min(reverbSample, 1.0), -1.0)
                    floatBuffer[i] = clampedSample
                }

            default:
                print("Unsupported bytesPerSample format: \(bytesPerSample)")
            }
        }
    }
    private func applyAudioEcho(_ frame: AgoraAudioFrame) {
        // Define echo parameters
        let delayInMs: Int = 100 // Delay time in milliseconds (adjust as needed)
        let gain: Float = 0.5 // Adjust the gain factor for the echo (0.0 to 1.0)

        if let buffer = frame.buffer {
            let bytesPerSample = frame.bytesPerSample
            let totalSamples = frame.samplesPerChannel * frame.channels
            let sampleRate = frame.samplesPerSec

            let delaySamples = Int(Float(sampleRate) * Float(delayInMs) / 1000.0)

            switch bytesPerSample {
            case 2: // Int16 format (16-bit signed integer)
                let int16Buffer = buffer.bindMemory(to: Int16.self, capacity: totalSamples)

                // Apply echo to the audio samples
                for i in 0..<totalSamples {
                    let echoIndex = i - delaySamples
                    if echoIndex >= 0 && echoIndex < totalSamples {
                        let echoSample = Float(int16Buffer[echoIndex]) * gain
                        let originalSample = Float(int16Buffer[i])
                        let echoedSample = originalSample + echoSample

                        // Clip the echoed sample to avoid clipping and distortion
                        let clampedSample = max(min(echoedSample, Float(Int16.max)), Float(Int16.min))
                        int16Buffer[i] = Int16(clampedSample)
                    }
                }

            case 4: // Float32 format (32-bit floating-point)
                let floatBuffer = buffer.bindMemory(to: Float.self, capacity: totalSamples)

                // Apply echo to the audio samples
                for i in 0..<totalSamples {
                    let echoIndex = i - delaySamples
                    if echoIndex >= 0 && echoIndex < totalSamples {
                        let echoSample = floatBuffer[echoIndex] * gain
                        let originalSample = floatBuffer[i]
                        let echoedSample = originalSample + echoSample

                        // Clip the echoed sample to avoid clipping and distortion
                        let clampedSample = max(min(echoedSample, 1.0), -1.0)
                        floatBuffer[i] = clampedSample
                    }
                }

            default:
                print("Unsupported bytesPerSample format: \(bytesPerSample)")
            }
        }
    }

}
