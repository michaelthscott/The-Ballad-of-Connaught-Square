//
//  ContentView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            TabView {
                PerformanceView()
                    .tabItem { Label("Performance", systemImage: "theatermasks") }
				SettingsView()
					.tabItem { Label("Settings", systemImage: "gear") }
            }
        }
    }
}

#Preview("ContentView", traits: .modifier(PreviewBallad()), .modifier(PreviewSpeakers()), .modifier(PreviewPerformance())) {
    ContentView()
}
