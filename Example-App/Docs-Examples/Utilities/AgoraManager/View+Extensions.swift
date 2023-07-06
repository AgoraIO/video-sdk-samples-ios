//
//  View+Extensions.swift
//  Docs-Examples
//
//  Created by Max Cobb on 06/07/2023.
//

import SwiftUI

extension View {
    @ViewBuilder
    func onAppear(performAsync action: @escaping () async -> Void) -> some View {
        self.onAppear {
            Task { await action() }
        }
    }
}
