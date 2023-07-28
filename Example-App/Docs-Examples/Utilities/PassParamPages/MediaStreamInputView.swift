//
//  MediaStreamInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 24/07/2023.
//

import SwiftUI
import UIKit
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
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                    // Clear the previously selected media
                    videoURL = nil
                    videoThumbnail = nil

                    withAnimation { self.isImagePickerPresented.toggle() }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    GitHubButtonView(continueTo.docPath)
                }
            }), label: {
                Text("Join Channel")
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
}

struct MediaStreamInputView_Previews: PreviewProvider {
    static var previews: some View {
        MediaStreamInputView(continueTo: StreamMediaView.self)
    }
}
