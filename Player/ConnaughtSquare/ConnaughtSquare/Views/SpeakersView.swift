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
			Picker(selection: $speakers.firstSpeaker, label: label("First", width: 50.0)) {
                ForEach(speakers.availableSpeakers) { speaker in
                    Text(speaker.name).tag(speaker)
                }
            }
            Picker(selection: $speakers.secondSpeaker, label: label("Second", width: 50.0)) {
                ForEach(speakers.availableSpeakers) { speaker in
                    Text(speaker.name).tag(speaker)
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
