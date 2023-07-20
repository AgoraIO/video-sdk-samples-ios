//
//  VisualEffectView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 20/07/2023.
//

import SwiftUI

#if os(iOS)
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(
        context: UIViewRepresentableContext<Self>
    ) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(
        _ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>
    ) { uiView.effect = effect }
}
#elseif os(macOS)
struct VisualEffectView: NSViewRepresentable {
  var material: NSVisualEffectView.Material
  var blendingMode: NSVisualEffectView.BlendingMode
  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    return view
  }
  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
  }
}
#endif
