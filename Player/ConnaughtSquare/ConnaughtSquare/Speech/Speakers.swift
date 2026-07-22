//
//  Speakers.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 26/11/2023.
//

import Foundation
import AVFoundation

// This used to be our prefered speakers: ["Daniel", "Oliver", "Arthur", "Kate", "Serena", "Martha"]

enum CurrentSpeaker {
    case first, second
}

@Observable final class Speakers {
    static let maxSelectedSpeakers: Int = 2
    static let language = "en-GB"

    var availableSpeakers: [Speaker]
    var firstSpeaker: Speaker
    var secondSpeaker: Speaker
    private var currentSpeaker: CurrentSpeaker = .first
    
    init() {
        let availableSpeakers = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == Self.language }.compactMap { Speaker(voice: $0) }.sorted()
        
        switch availableSpeakers.count {
        case 0: 
            fatalError("No available voices")
        case 1:
            firstSpeaker = availableSpeakers[0]
            secondSpeaker = availableSpeakers[0]
        default:
            firstSpeaker = availableSpeakers[0]
            secondSpeaker = availableSpeakers[1]
        }
		
		self.availableSpeakers = availableSpeakers
    }
    
    var selectedSpeakers: [Speaker] {
        [firstSpeaker, secondSpeaker]
    }

    var nextSpeaker: Speaker {
        switch currentSpeaker {
        case .first:
            defer { currentSpeaker = .second }
            return secondSpeaker
        case .second:
            defer { currentSpeaker = .first }
            return firstSpeaker
        }
    }
}

