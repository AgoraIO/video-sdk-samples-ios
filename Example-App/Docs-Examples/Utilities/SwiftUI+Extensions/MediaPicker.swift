//
//  MediaPicker.swift
//  Docs-Examples
//
//  Created by Max Cobb on 24/07/2023.
//

import SwiftUI
import AVKit

#if os(iOS) && !targetEnvironment(simulator)
// MediaPicker view to present UIImagePickerController
struct MediaPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Binding var videoThumbnail: Image?

    func makeCoordinator() -> MediaPickerCoordinator {
        MediaPickerCoordinator(url: $videoURL, thumbnail: $videoThumbnail)
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        // Set mediaTypes to include both photos and videos
        picker.mediaTypes = ["public.movie"]
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

class MediaPickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var videoURL: URL?
    @Binding var videoThumbnail: Image?

    init(url: Binding<URL?>, thumbnail: Binding<Image?>) {
        _videoURL = url
        _videoThumbnail = thumbnail
    }

    // Handle image or video selection selection
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let videoURL = info[.mediaURL] as? URL {
            self.videoURL = videoURL
            generateVideoThumbnail(from: videoURL)
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    // Function to generate a thumbnail from the video URL
    private func generateVideoThumbnail(from videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            #if os(iOS)
            videoThumbnail = Image(uiImage: UIImage(cgImage: cgImage))
            #endif
        } catch {
            print("Failed to generate video thumbnail: \(error.localizedDescription)")
            videoThumbnail = nil
        }
    }
}

struct MediaPicker_Previews: PreviewProvider {
    static var previews: some View {
        MediaPicker(videoURL: .constant(nil), videoThumbnail: .constant(nil))
    }
}
#endif
