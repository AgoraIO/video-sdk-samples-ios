//
//  DocsAppConfig.swift
//  Docs-Examples
//
//  Created by Max Cobb on 29/06/2023.
//

import Foundation
import SwiftUI

public struct DocsAppConfig: Codable {
    static var shared: DocsAppConfig {
        guard let fileUrl = Bundle.main.url(forResource: "config", withExtension: "json"),
              let jsonData  = try? Data(contentsOf: fileUrl) else { fatalError() }

        let decoder = JSONDecoder()
        var obj = try! decoder.decode(DocsAppConfig.self, from: jsonData)
        if (obj.rtcToken ?? "").isEmpty {
            obj.rtcToken = nil
        }
        return obj
    }

    var uid: UInt
    // APP ID from https://console.agora.io
    var appId: String
    /// Channel prefil text to join
    var channel: String
    /// Generate RTC Token at ...
    var rtcToken: String?
    /// Generate Signaling Token at ...
    var signalingToken: String
    /// Mode for encryption, choose from 1-8
    var encryptionMode: Int
    /// RTC encryption salt
    var salt: String
    /// RTC encryption key
    var cipherKey: String
    /// Add Proxy Server URL
    var proxyUrl: String
    /// Add Proxy type from none, tcp, udp
    var proxyType: String
    /// Add Token Generator URL
    var tokenUrl: String
    /// ID used for screen shares by default
    var screenShareId: UInt
}
