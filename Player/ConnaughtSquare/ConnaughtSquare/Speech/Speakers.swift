//
//  Speakers.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 26/11/2023.
//

import Foundation
import AVFoundation

// This used to be our prefered speakers: ["Daniel", "Oliver", "Arthur", "Kate", "Serena", "Martha"]

/// The voices that recite the ballad, one for each of the score's roles.
@Observable final class Speakers {
    static let language = "en-GB"

    let availableSpeakers: [Speaker]
    /// The names of the score's roles.
    let roles: [String]
    /// The voice for each role, in the same order as the roles.
    var voices: [Speaker]

    /// Creates speakers for the standard score's roles.
    convenience init() {
        self.init(roles: Score.standard.voices.roles)
    }

    /// Creates speakers for the roles, giving them the available voices in turn.
    init(roles: [String]) {
        var availableSpeakers = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == Self.language }.map { Speaker(voice: $0) }.sorted()
        // Without a British English voice, fall back to the default voice for the user's language.
        if availableSpeakers.isEmpty, let voice = AVSpeechSynthesisVoice(language: nil) {
            availableSpeakers = [Speaker(voice: voice)]
        }
        guard !availableSpeakers.isEmpty else {
            fatalError("No available voices")
        }

        self.availableSpeakers = availableSpeakers
        self.roles = roles
        // With fewer voices than roles, the voices are shared.
        voices = roles.indices.map { availableSpeakers[$0 % availableSpeakers.count] }
    }

    /// The voice for the role. A role outside the roles wraps around them, and without any roles
    /// the first available voice speaks.
    func speaker(forRole role: Int) -> Speaker {
        guard !voices.isEmpty else { return availableSpeakers[0] }
        return voices[(role % voices.count + voices.count) % voices.count]
    }
}
