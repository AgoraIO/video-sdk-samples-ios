//
//  NavigationLazyView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 20/07/2023.
//

import SwiftUI

internal struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
