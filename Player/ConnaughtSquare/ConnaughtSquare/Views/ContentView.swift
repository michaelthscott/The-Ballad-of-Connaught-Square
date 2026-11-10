//
//  ContentView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        // On macOS the settings are in the Settings window instead.
        PerformanceTab()
        #else
        VStack {
            TabView {
                PerformanceTab()
                    .tabItem { Label("Performance", systemImage: "theatermasks") }
				SettingsTab()
					.tabItem { Label("Settings", systemImage: "gear") }
            }
        }
        #endif
    }
}

#Preview("ContentView", traits: .modifier(PreviewBallad()), .modifier(PreviewSpeakers()), .modifier(PreviewPerformance())) {
    ContentView()
}
