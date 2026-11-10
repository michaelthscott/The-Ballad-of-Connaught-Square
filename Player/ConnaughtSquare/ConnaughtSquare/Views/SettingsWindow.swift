//
//  SettingsWindow.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 10/11/2026.
//

#if os(macOS)
import SwiftUI

/// The macOS Settings window, opened from the app menu or with ⌘,; on iOS the settings are a tab of their own.
struct SettingsWindow: View {
	var body: some View {
		TabView {
			Tab("Voices", systemImage: "person.wave.2") {
				Form {
					SpeakersView()
				}
				.frame(width: 450)
			}
			Tab("Tag Order", systemImage: "list.number") {
				VStack {
					TagOrderView()
					TagListView()
				}
				.padding()
				.frame(width: 450, height: 500)
			}
		}
	}
}

#Preview("SettingsWindow", traits: .modifier(PreviewBallad()), .modifier(PreviewSpeakers())) {
	SettingsWindow()
}
#endif
