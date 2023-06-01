//
//  ContentView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 20/03/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Get Started") {
                    NavigationLink("Basic Implementation") {
                        ChannelInputView(continueTo: GettingStartedView.self) // <- SwiftUI Example
                    }
                    NavigationLink("UIKit Implementation") {
                        EmptyView()
                    }
                }
                Section("Develop") {
                    NavigationLink("Secure Authentication") {
                        TokenAuthInputView(continueTo: TokenAuthenticationView.self) // <- SwiftUI Example
                    }
                    NavigationLink("Call Quality") {
                        ChannelInputView(continueTo: CallQualityView.self) // <- SwiftUI Example
                    }
                    NavigationLink("Screen share, volume control and mute") {
                        ChannelInputView(continueTo: ScreenShareAndVolumeView.self)
                    }
                    NavigationLink("Audio and voice effects") {
                        EmptyView()
                    }
                    NavigationLink("Custom video and audio sources") {
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
