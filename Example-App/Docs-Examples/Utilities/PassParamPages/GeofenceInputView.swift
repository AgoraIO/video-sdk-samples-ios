//
//  GeofenceInputView.swift
//  Docs-Examples
//
//  Created by Max Cobb on 22/07/2023.
//

import SwiftUI
import AgoraRtcKit

/// A protocol for views that require a `channelId` string as input.
protocol HasGeoInput: View, HasDocPath {
    init(channelId: String, regions: GeofencingManager.RegionsType)
}

extension GeofencingView: HasGeoInput {}

fileprivate extension AgoraAreaCodeType {
    var humanReadable: String {
        switch self {
        case .CN: return "Mainland China"
        case .NA: return "North America"
        case .EUR: return "Europe"
        case .AS: return "Asia (Excluding Mainland China)"
        case .JP: return "Japan"
        case .IN: return "India"
        case .global: return "Global"
        @unknown default: return "Unknown"
        }
    }
}
/// A view that takes a user inputted `channelId` string and navigates to a view
/// which conforms to the `HasChannelInput` protocol.
///
/// The generic parameter `Content` specifies the type of view to navigate to,
/// and must conform to the `HasChannelInput` protocol.
struct GeofenceInputView<Content: HasGeoInput>: View {
    /// The user inputted `channelId` string.
    @State var channelId: String = DocsAppConfig.shared.channel
    /// The type of view to navigate to.
    var continueTo: Content.Type

    @State private var selectedRegionIndex = 0
    @State private var selectedRegion: AgoraAreaCodeType = .global
    @State private var selectedRegions: Set<AgoraAreaCodeType> = []

    var body: some View {
        VStack {
            TextField("Enter channel id", text: $channelId).textFieldStyle(.roundedBorder).padding([.bottom])
            Section("Select Region") {
                Picker("Select Region Type", selection: $selectedRegionIndex) {
                    Text("Absolute").tag(0)
                    Text("Inclusive").tag(1)
                    Text("Exclusive").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedRegionIndex) { newValue in
                    switch newValue {
                    case 1, 2: selectedRegions = Set(
                        [AgoraAreaCodeType.NA, .EUR, .CN, .AS, .JP, .IN]
                            .shuffled().prefix(.random(in: 1...3)))
                    default: break
                    }
                }

                switch selectedRegionIndex {
                case 0: // Absolute
                    Picker("Select Region", selection: $selectedRegion) {
                        ForEach([AgoraAreaCodeType.global, .NA, .EUR, .CN, .AS, .JP, .IN], id: \.self) { region in
                            Text(region.humanReadable).tag(region)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                case 1, 2: // Inclusive, Exclusive
                    ForEach(
                        [AgoraAreaCodeType.NA, .EUR, .CN, .AS, .JP, .IN], id: \.self
                    ) { region in
                        Toggle(region.humanReadable, isOn: Binding(get: {
                            selectedRegions.contains(region)
                        }, set: { toggleValue in
                            if toggleValue {
                                selectedRegions.insert(region)
                            } else {
                                selectedRegions.remove(region)
                            }
                        }))
                    }
                    let textTitle = (selectedRegionIndex == 1 ? "Only permitting" : "Global, excluding") + ": "
                    Text("\(textTitle) \(regionsList)")
                default: Text("Unknown Error")
                }
            }

            NavigationLink(destination: NavigationLazyView(continueTo.init(
                channelId: channelId.trimmingCharacters(in: .whitespaces),
                regions: .absolute(.global)
            ).navigationTitle(continueTo.docTitle)), label: {
                Text("Join Channel")
            }).disabled(channelId.isEmpty || !regionSelected())
                .buttonStyle(.borderedProminent)
        }.onAppear {
            channelId = DocsAppConfig.shared.channel
        }.padding().navigationTitle("Geofence Input")
    }
    var regionsList: String {
        selectedRegions.map { $0.humanReadable }.joined(separator: ", ")
    }
    func regionSelected() -> Bool {
        switch self.selectedRegionIndex {
        case 0, 2: return true
        case 1:
            return !selectedRegions.isEmpty
        default: return false
        }
    }
    func getRegionSelection() -> GeofencingManager.RegionsType {
        switch self.selectedRegionIndex {
        case 0: return .absolute(selectedRegion)
        case 1: return .inclusive(Array(selectedRegions))
        case 2: return .exclusive(Array(selectedRegions))
        default: fatalError("no valid default case.")
        }
    }
}

struct GeofenceInputView_Previews: PreviewProvider {
    static var previews: some View {
        GeofenceInputView(continueTo: GeofencingView.self)
    }
}
