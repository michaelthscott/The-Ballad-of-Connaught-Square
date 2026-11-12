//
//  SpeakersView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 19/11/2023.
//

import SwiftUI
import AVFoundation

struct SpeakersView: View {
	@Environment(Speakers.self) var speakers
    
    var body: some View {
		@Bindable var speakers = speakers
        VStack(alignment: .leading) {
            VoiceDownloadNotice()
            // The roles are fixed by the score, so their indices are stable identities.
            ForEach(speakers.roles.indices, id: \.self) { index in
                Picker(selection: $speakers.voices[index], label: Text(speakers.roles[index])) {
                    ForEach(speakers.availableSpeakers) { speaker in
                        Text(speaker.name).tag(speaker)
                    }
                }
                volumeSlider(forRole: index)
            }
        }
    }
	
	/// How loud the role is played, so that two roles in the same voice can differ. Its title clears
	/// the role's volume, so that the role plays at its voice's standard volume, which matches the
	/// voices. A change is heard from the role's next part.
	func volumeSlider(forRole role: Int) -> some View {
		let name = speakers.roles[role]
		let volume = Binding<Float> {
			speakers.volume(forRole: role)
		} set: {
			speakers.volumes[name] = $0
		}
		return LabeledContent {
			HStack {
				Slider(value: volume, in: 0...1)
				Text(volume.wrappedValue, format: .number.precision(.fractionLength(2)))
					.monospacedDigit()
					.frame(width: 44, alignment: .trailing)
			}
		} label: {
			Button("\(name) volume") {
				speakers.volumes[name] = nil
			}
			.buttonStyle(.plain)
			.help("Click to reset to the volume that matches the voices")
		}
	}
}

#Preview("SpeakersView", traits: .modifier(PreviewSpeakers())) {
    SpeakersView()
}
