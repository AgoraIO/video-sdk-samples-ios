//
//  RPSystemBroadcastPickerWrapper.swift
//  Docs-Examples
//
//  Created by Max Cobb on 24/05/2023.
//

import SwiftUI
import ReplayKit

struct RPSystemBroadcastPickerWrapper: UIViewRepresentable {

    var preferredExtension: String?
    var showsMicrophone: Bool = false

    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        broadcastPicker.preferredExtension = self.preferredExtension
        broadcastPicker.showsMicrophoneButton = self.showsMicrophone
        return broadcastPicker
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}
