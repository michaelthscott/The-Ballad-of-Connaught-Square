//
//  MusicSettingsView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 11/11/2026.
//

import SwiftUI

/// How loud the music is played against the voices. It's the performance's own, heard at once,
/// and the app keeps it between launches. Clicking the title returns it to full volume.
///
/// It's a section, to go in a form beside the voices.
struct MusicSettingsView: View {
	@Environment(Performance.self) var performance

	var body: some View {
		@Bindable var performance = performance
		Section("Music") {
			LabeledContent {
				HStack {
					Slider(value: $performance.musicVolume, in: 0...1)
					Text(performance.musicVolume, format: .number.precision(.fractionLength(2)))
						.monospacedDigit()
						.frame(width: 44, alignment: .trailing)
				}
			} label: {
				Button("Music volume") {
					performance.musicVolume = 1
				}
				.buttonStyle(.plain)
				.help("Click to reset to full volume")
			}
		}
	}
}

#Preview("MusicSettingsView", traits: .modifier(PreviewPerformance())) {
	Form {
		MusicSettingsView()
	}
	.formStyle(.grouped)
}
