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

    let availableSpeakers: [Speaker]
    var firstSpeaker: Speaker
    var secondSpeaker: Speaker
    private var currentSpeaker: CurrentSpeaker = .first

    init() {
        var availableSpeakers = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == Self.language }.map { Speaker(voice: $0) }.sorted()
        // Without a British English voice, fall back to the default voice for the user's language.
        if availableSpeakers.isEmpty, let voice = AVSpeechSynthesisVoice(language: nil) {
            availableSpeakers = [Speaker(voice: voice)]
        }

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

    /// Returns the speaker whose turn it is, and passes the turn to the other speaker.
    /// The turns start with the second speaker.
    func takeTurn() -> Speaker {
        switch currentSpeaker {
        case .first:
            currentSpeaker = .second
            return secondSpeaker
        case .second:
            currentSpeaker = .first
            return firstSpeaker
        }
    }

    /// Starts the turns again, so that the next speaker is the second speaker.
    func resetTurns() {
        currentSpeaker = .first
    }
}

