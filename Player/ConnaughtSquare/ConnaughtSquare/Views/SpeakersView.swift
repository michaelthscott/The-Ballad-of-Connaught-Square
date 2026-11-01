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
        VStack {
            // The roles are fixed by the score, so their indices are stable identities.
            ForEach(speakers.roles.indices, id: \.self) { index in
                Picker(selection: $speakers.voices[index], label: label(speakers.roles[index], width: 50.0)) {
                    ForEach(speakers.availableSpeakers) { speaker in
                        Text(speaker.name).tag(speaker)
                    }
                }
            }
        }
        .padding()
    }
	
	func label(_ text: String, width: Double) -> some View {
		Text(text)
			.frame(width: width, alignment: .trailing)
	}
}

#Preview("SpeakersView", traits: .modifier(PreviewSpeakers())) {
    SpeakersView()
}
