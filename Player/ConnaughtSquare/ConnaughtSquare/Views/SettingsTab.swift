//
//  SettingsTab.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 18/12/2023.
//

import SwiftUI

struct SettingsTab: View {
	@Environment(Ballad.self) var ballad
	@State private var isShowingSheet = false
	
	func didDismiss() {
		// Handle the dismissing action.
	}

	var body: some View {
		VStack(spacing: 0) {
			Form {
				Section {
					SpeakersView()
				} header: {
					Text("Speakers")
						.font(.largeTitle)
				}
				MusicSettingsView()
				RecitationSettingsView()
				Section {
					TagOrderView()
				} header: {
					Text("Tags Order")
						.font(.largeTitle)
				}
				Section {
					TagListView()
				} header: {
					Text("Reorder Tags")
						.font(.largeTitle)
				}
				Section {
					VersionView()
				}
			}
		}
	}
}

#Preview("Settings", traits: .modifier(PreviewBallad()), .modifier(PreviewSpeakers()), .modifier(PreviewPerformance())) {
	SettingsTab()
}
