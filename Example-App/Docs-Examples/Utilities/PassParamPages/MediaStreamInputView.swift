//
//  MediaStreamInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 24/07/2023.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation

protocol HasMediaInput: HasDocPath {
    init(channelId: String, url: URL)
}

extension StreamMediaView: HasMediaInput {}

struct MediaStreamInputView<Content: HasMediaInput>: View {
    /// The user inputted `channelId` string.
    @State private var channelId: String = DocsAppConfig.shared.channel
    /// The type of view to navigate to.
    var continueTo: Content.Type
    // New @State variable to hold the selected media
    @State private var videoURL: URL?
    @State private var videoThumbnail: Image?
    @State var isImagePickerPresented = false

    #if os(macOS)
    @State private var videoBookmark: Data?
    #endif
    var body: some View {
        VStack {
            TextField("Enter channel id", text: $channelId).textFieldStyle(.roundedBorder).padding()
            Button(action: {
                videoURL = nil // Clear the previously selected media
                // Present the media picker
                #if targetEnvironment(simulator)
                print("Cannot select media on the simulator.")
                #else
                DispatchQueue.main.async {
                    #if canImport(UIKit)
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                    #endif
                    // Clear the previously selected media
                    videoURL = nil
                    videoThumbnail = nil

                    #if os(macOS)
                    self.showSelectMediaPanel()
                    #else
                    withAnimation { self.isImagePickerPresented.toggle() }
                    #endif
                }
                #endif
            }, label: {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text((videoURL == nil ? "Select" : "Change") + " Media")
                }
            }).buttonStyle(.borderedProminent).padding()

            if let thumbnail = videoThumbnail {
                #if os(iOS)
                thumbnail.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                #endif
            }

            NavigationLink(destination: NavigationLazyView(continueTo.init(
                channelId: channelId.trimmingCharacters(in: .whitespaces),
                url: videoURL!
            ).navigationTitle(continueTo.docTitle).toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    GitHubButtonView(continueTo.docPath)
                }
                #endif
            }), label: {
                Text(LocalizedStringKey("params-continue-button"))
            }).disabled(channelId.isEmpty || videoURL == nil)
                .buttonStyle(.borderedProminent)
                .navigationTitle("Media Stream Input")
        }.onAppear {
            channelId = DocsAppConfig.shared.channel
        }.sheet(isPresented: $isImagePickerPresented, content: {
            #if os(iOS) && !targetEnvironment(simulator)
            MediaPicker(videoURL: $videoURL, videoThumbnail: $videoThumbnail)
            #endif
        })
    }

    #if os(macOS)
    func showSelectMediaPanel() {
        let openPanel = NSOpenPanel()

        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.movie]
        if openPanel.runModal() == .OK, let url = openPanel.url {
            self.videoBookmark = try? url.bookmarkData(options: .suitableForBookmarkFile)
            var isStale = false
            if let videoURL = try? URL(
                resolvingBookmarkData: self.videoBookmark!, bookmarkDataIsStale: &isStale),
               !isStale {
                let vidNsUrl = videoURL as NSURL
                self.videoURL = videoURL
            }
        }
    }
    #endif
}

struct MediaStreamInputView_Previews: PreviewProvider {
    static var previews: some View {
        MediaStreamInputView(continueTo: StreamMediaView.self)
    }
}
