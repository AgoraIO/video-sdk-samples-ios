//
//  GitHubButtonView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 28/07/2023.
//

import SwiftUI

struct GitHubButtonView: View {
    let url: URL?
    static let repoBase = "https://github.com/AgoraIO/video-sdk-samples-ios/tree/main/"

    init(_ path: String) {
        self.url = URL(string: GitHubButtonView.repoBase + path)
        print("url: \(self.url?.absoluteString ?? "")")
    }

    var body: some View {
        if let url {
            Button(action: {
                openURL(url)
            }, label: {
                #if os(iOS)
                Image(uiImage: UIImage(
                    named: "github-mark\(colorScheme == .dark ? "-white" : "")")!
                ).resizable().frame(width: 24, height: 24)
                #elseif os(macOS)
                Image(nsImage: NSImage(
                    named: "github-mark\(colorScheme == .dark ? "-white" : "")")!
                ).resizable().frame(width: 24, height: 24)
                #endif
            })
        }
    }

    func openURL(_ url: URL) {
        #if os(iOS)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    @Environment(\.colorScheme) var colorScheme
}

struct GitHubButtonView_Previews: PreviewProvider {
    static var previews: some View {
        GitHubButtonView(".")
    }
}
