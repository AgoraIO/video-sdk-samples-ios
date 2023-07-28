import AgoraRtcKit

protocol HasModifyVideo {
    var videoModification: VideoModification { get }
}

public class ModifyVideoFrameDelegate: NSObject, AgoraVideoFrameDelegate {

    var modifyController: any HasModifyVideo

    public func onCapture(_ videoFrame: AgoraOutputVideoFrame, sourceType: AgoraVideoSourceType) -> Bool {
        guard let pixelBuffer = videoFrame.pixelBuffer else { return true }
        var outputBuffer: CVPixelBuffer?
        switch modifyController.videoModification {
        case .comic: outputBuffer = applyCIFilter(named: "CIComicEffect", to: pixelBuffer)
        case .invert: outputBuffer = applyCIFilter(named: "CIColorInvert", to: pixelBuffer)
        case .zoom: outputBuffer = zoomPixelBuffer(pixelBuffer)
        case .mirrorVertical: outputBuffer = flipPixelBufferVertical(pixelBuffer)
        case .none: break
        }
        if let outputBuffer {
            copyPixelBuffer(outputBuffer, to: videoFrame.pixelBuffer!)
        }
        return true
    }

    /// Copies pixel data from the source CVPixelBuffer to the destination CVPixelBuffer.
    ///
    /// - Parameters:
    ///   - sourcePixelBuffer: The source CVPixelBuffer from which to copy the pixel data.
    ///   - destinationPixelBuffer: The destination CVPixelBuffer to which the pixel data will be copied.
    fileprivate func copyPixelBuffer(_ sourcePixelBuffer: CVPixelBuffer, to destinationPixelBuffer: CVPixelBuffer) {
        // Lock the source and destination pixel buffers for reading and writing.
        CVPixelBufferLockBaseAddress(sourcePixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(destinationPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        // Get the base addresses of the source and destination pixel buffers.
        guard let sourceBaseAddress = CVPixelBufferGetBaseAddress(sourcePixelBuffer),
              let destinationBaseAddress = CVPixelBufferGetBaseAddress(destinationPixelBuffer) else {
            return
        }

        // Get the bytes per row (stride) of the source and destination pixel buffers.
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(sourcePixelBuffer)
        let destinationBytesPerRow = CVPixelBufferGetBytesPerRow(destinationPixelBuffer)

        // Get the height of the source pixel buffer.
        let height = CVPixelBufferGetHeight(sourcePixelBuffer)

        // Calculate the data size to be copied based on the height and minimum bytes per row of both buffers.
        let dataSize = height * min(sourceBytesPerRow, destinationBytesPerRow)

        // Copy the pixel data from the source buffer to the destination buffer using memcpy.
        memcpy(destinationBaseAddress, sourceBaseAddress, dataSize)

        // Unlock the source and destination pixel buffers.
        CVPixelBufferUnlockBaseAddress(destinationPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferUnlockBaseAddress(sourcePixelBuffer, .readOnly)
    }

    // Indicate the video frame mode of the observer
    public func getVideoFrameProcessMode() -> AgoraVideoFrameProcessMode {
        // The process mode of the video frame: readOnly, readWrite
        // Default is `.readOnly` function is required to change the output.
        return .readWrite
    }

    // Sets the video frame type preference
    public func getVideoFormatPreference() -> AgoraVideoFormat {
        // cvPixelBGRA is the default, you can omit this.
        return .cvPixelBGRA
    }

    // Sets the frame position for the video observer
    public func getObservedFramePosition() -> AgoraVideoFramePosition {
        // postCapture is default, you can omit this.
        return .postCapture
    }

    init(modifyController: any HasModifyVideo) {
        self.modifyController = modifyController
    }
}

// MARK: - Pixel Buffer Modifiers

public extension ModifyVideoFrameDelegate {
    /// Zooms the given pixel buffer by the specified factor.
    /// The function applies a zooming effect to the input pixel buffer using Core Image.
    /// - Parameters:
    ///   - pixelBuffer: The source CVPixelBuffer to be zoomed.
    ///   - zoomFactor: The scaling factor for zooming. Default is 1.5.
    /// - Returns: A new CVPixelBuffer with the zoomed content or nil if the zoom fails.
    func zoomPixelBuffer(_ pixelBuffer: CVPixelBuffer, zoomFactor: CGFloat = 1.5) -> CVPixelBuffer? {
        let inputImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Calculate the zoomed image size
        let originalWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let originalHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        // Calculate the offset to center the zoomed image
        let offsetX = originalWidth * (1 - zoomFactor) / (2 * zoomFactor)
        let offsetY = originalHeight * (1 - zoomFactor) / (2 * zoomFactor)

        // Create a CGAffineTransform to scale and offset the image
        let scaleTransform = CGAffineTransform(scaleX: zoomFactor, y: zoomFactor).translatedBy(x: offsetX, y: offsetY)
        let scaledImage = inputImage.transformed(by: scaleTransform)

        // Create a CIContext for rendering
        let context = CIContext()

        // Render the scaled CIImage into a new pixel buffer
        var zoomedPixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            nil, Int(originalWidth), Int(originalHeight),
            CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &zoomedPixelBuffer
        )

        guard let zoomedBuffer = zoomedPixelBuffer else {
            print("Failed to create zoomed pixel buffer.")
            return nil
        }

        context.render(scaledImage, to: zoomedBuffer)

        return zoomedPixelBuffer
    }

    /// Applies a Core Image filter to the given pixel buffer.
    /// The function applies the specified Core Image filter to the input pixel buffer using Core Image.
    /// - Parameters:
    ///   - filterName: The name of the Core Image filter to apply.
    ///   - pixelBuffer: The source CVPixelBuffer to which the filter will be applied.
    /// - Returns: A new CVPixelBuffer with the filter effect applied or nil if the filter fails.
    func applyCIFilter(named filterName: String, to pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let inputImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Calculate the image size
        let originalWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let originalHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        // Apply filter to the image
        guard let comicEffectFilter = CIFilter(name: filterName) else { return nil }
        comicEffectFilter.setValue(inputImage, forKey: kCIInputImageKey)

        // Create a CIContext for rendering
        let context = CIContext()

        // Render the modified CIImage into a new pixel buffer
        var filteredPixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            nil, Int(originalWidth), Int(originalHeight),
            CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &filteredPixelBuffer
        )

        guard let filterBuffer = filteredPixelBuffer else {
            print("Failed to create modified pixel buffer.")
            return nil
        }

        context.render(comicEffectFilter.outputImage!, to: filterBuffer)

        return filteredPixelBuffer
    }

    /// Flips the given pixel buffer vertically.
    /// The function performs a vertical flip on the input pixel buffer.
    /// - Parameters:
    ///   - pixelBuffer: The source CVPixelBuffer to be flipped.
    /// - Returns: A new CVPixelBuffer with the vertically flipped content or nil if the flip fails.
    func flipPixelBufferVertical(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        // Get the video frame dimensions and pixel format from the AgoraOutputVideoFrame
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

        // Create a new pixel buffer with the same dimensions and pixel format.
        var flippedPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, width, height, pixelFormat, nil, &flippedPixelBuffer)
        guard status == kCVReturnSuccess else {
            print("Failed to create flipped pixel buffer.")
            return nil
        }

        // Lock the original and flipped pixel buffers for reading and writing
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(flippedPixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        // Get the raw pixel data pointers from the original and flipped pixel buffers
        let srcBuffer = CVPixelBufferGetBaseAddress(pixelBuffer)
        let destBuffer = CVPixelBufferGetBaseAddress(flippedPixelBuffer!)

        // Calculate the row bytes for the pixel buffers
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Perform the vertical flipping by copying the original pixel buffer into the flipped one.
        for y in 0..<height {
            let srcY = height - y - 1 // Vertical flipping happens here
            memcpy(destBuffer! + (srcY * bytesPerRow), srcBuffer! + (y * bytesPerRow), bytesPerRow)
        }

        // Unlock the pixel buffers
        CVPixelBufferUnlockBaseAddress(flippedPixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        return flippedPixelBuffer
    }
}
