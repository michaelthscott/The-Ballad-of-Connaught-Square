//
//  Speakers.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 26/11/2023.
//

import Foundation
import AVFoundation

// This used to be our prefered speakers: ["Daniel", "Oliver", "Arthur", "Kate", "Serena", "Martha"]

/// The voices that recite the ballad, one for each role.
@Observable final class Speakers {
    static let language = "en-GB"

    let availableSpeakers: [Speaker]
    /// The names of the roles.
    let roles: [String]
    /// The voice for each role, in the same order as the roles.
    var voices: [Speaker]

    /// Creates speakers for the standard roles.
    convenience init(installedVoices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices()) {
        self.init(roles: VoiceNotation.standard.roles, installedVoices: installedVoices)
    }

    /// Creates speakers for the roles, giving them the available voices in turn. The available
    /// voices are chosen from the installed voices, which are listed afresh unless given.
    init(roles: [String], installedVoices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices()) {
        var availableSpeakers = installedVoices.filter { $0.language == Self.language }.map { Speaker(voice: $0) }.sorted()
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

    /// How far to either side the outermost roles stand, from 0 in the centre to 1 at the edge.
    /// Short of the edge, so a little of each voice reaches the other ear, which is less tiring on headphones.
    static let stereoWidth: Float = 0.75

    /// Where the role stands in stereo, from -1 on the left to 1 on the right. The roles are spread
    /// evenly from left to right in order, a single role stands in the centre, and a role outside
    /// the roles wraps around them.
    func pan(forRole role: Int) -> Float {
        guard roles.count > 1 else { return 0 }
        let position = (role % roles.count + roles.count) % roles.count
        return Self.stereoWidth * (2 * Float(position) / Float(roles.count - 1) - 1)
    }
}
