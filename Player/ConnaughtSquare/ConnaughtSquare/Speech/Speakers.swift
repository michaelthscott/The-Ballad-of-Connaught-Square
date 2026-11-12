//
//  Speakers.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 26/11/2023.
//

import Foundation
import AVFoundation

/// The voices that recite the ballad, one for each role.
///
/// The roles are recited by the enhanced downloads of Daniel and Arthur, in turn. Until they're
/// installed, other British English voices stand in, and the voices to download are listed, so
/// that the listener can be asked to install them.
@Observable final class Speakers {
    static let language = "en-GB"
    /// The voices the roles are recited in, in turn.
    static let preferredVoiceNames = ["Daniel", "Arthur"]

    /// What each voice's rate is multiplied by, so that the voices recite at the same pace.
    ///
    /// Arthur speaks the same lines in about five sixths of Daniel's time at any rate. Slowing the
    /// rate slows the voices much less than in proportion, 70% making speech only about a sixth
    /// longer, so it takes about two thirds of Daniel's rate to bring Arthur to his pace. Measured
    /// on 11/11/2026 with the enhanced downloads.
    static let paces: [String: Float] = ["Daniel": 1, "Arthur": 0.65]

    /// How loud each voice is played unless its role's volume is set, so that the voices sound
    /// equally loud. Arthur's speech is about 4 dB quieter than Daniel's, but peaks nearly as high,
    /// so Daniel is turned down rather than Arthur up, which would distort him. Measured on
    /// 11/11/2026 with the enhanced downloads.
    static let standardVolumes: [String: Float] = ["Daniel": 0.63, "Arthur": 1]

    /// How loud each role is played, from 0 to 1, by the role's name, so that two roles in the same
    /// voice can be told apart. A role without a volume plays at its voice's standard volume.
    var volumes: [String: Float] = [:]

    /// The voice's name without its quality, which its standard volume and pace are kept under.
    static func name(of voice: AVSpeechSynthesisVoice) -> String {
        VoiceSelection<AVSpeechSynthesisVoice>.baseName(of: voice.name)
    }

    /// How loud the voice is played unless its role's volume is set, from 0 to 1.
    static func standardVolume(of voice: AVSpeechSynthesisVoice) -> Float {
        standardVolumes[name(of: voice)] ?? 1
    }

    /// How loud the role is played, from 0 to 1: its own volume, or its voice's standard volume.
    /// A role outside the roles wraps around them.
    func volume(forRole role: Int) -> Float {
        guard !roles.isEmpty else { return Self.standardVolume(of: speaker(forRole: role).voice) }
        let name = roles[(role % roles.count + roles.count) % roles.count]
        return volumes[name] ?? Self.standardVolume(of: speaker(forRole: role).voice)
    }

    /// Where the roles' volumes are kept between launches. The volumes were once kept by voice,
    /// under another key, which is left unread.
    static let volumesDefaultsKey = "RoleVolumes"

    /// The roles' volumes saved in the defaults, each brought within 0 to 1. A role without a saved
    /// volume plays at its voice's standard volume.
    static func savedVolumes(in defaults: UserDefaults = .standard) -> [String: Float] {
        let saved = defaults.dictionary(forKey: volumesDefaultsKey) ?? [:]
        return saved.compactMapValues { value in
            (value as? NSNumber).map { min(max($0.floatValue, 0), 1) }
        }
    }

    /// Saves the volumes in the defaults, for the next launch.
    func saveVolumes(in defaults: UserDefaults = .standard) {
        defaults.set(volumes.mapValues { NSNumber(value: $0) }, forKey: Self.volumesDefaultsKey)
    }

    /// What the voice's rate is multiplied by to bring it to the same pace as the others.
    static func pace(of voice: AVSpeechSynthesisVoice) -> Float {
        paces[name(of: voice)] ?? 1
    }

    private(set) var availableSpeakers: [Speaker]
    /// The names of the preferred voices that aren't installed in enhanced quality or better.
    private(set) var missingVoiceNames: [String]
    /// The names of the roles.
    let roles: [String]
    /// The voice for each role, in the same order as the roles.
    var voices: [Speaker]

    /// Creates speakers for the standard roles.
    convenience init(installedVoices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices()) {
        self.init(roles: VoiceNotation.standard.roles, installedVoices: installedVoices)
    }

    /// Creates speakers for the roles, giving each its preferred voice, or another in its place.
    /// The voices are chosen from the installed voices, which are listed afresh unless given.
    init(roles: [String], installedVoices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices()) {
        let selection = Self.selection(from: installedVoices)
        let availableSpeakers = Self.availableSpeakers(in: selection)
        self.availableSpeakers = availableSpeakers
        missingVoiceNames = selection.missing
        self.roles = roles
        // With fewer voices than roles, the voices are shared.
        voices = roles.indices.map { role in
            selection.voice(forRole: role).map(Speaker.init) ?? availableSpeakers[role % availableSpeakers.count]
        }
    }

    private static func selection(from installedVoices: [AVSpeechSynthesisVoice]) -> VoiceSelection<AVSpeechSynthesisVoice> {
        VoiceSelection(installed: installedVoices, preferredNames: preferredVoiceNames, language: language)
    }

    /// The selection's voices, or without any British English voice, the default voice for the user's language.
    private static func availableSpeakers(in selection: VoiceSelection<AVSpeechSynthesisVoice>) -> [Speaker] {
        var availableSpeakers = selection.available.map(Speaker.init)
        if availableSpeakers.isEmpty, let voice = AVSpeechSynthesisVoice(language: nil) {
            availableSpeakers = [Speaker(voice: voice)]
        }
        guard !availableSpeakers.isEmpty else {
            fatalError("No available voices")
        }
        return availableSpeakers
    }

    /// Chooses the voices again from those installed now, as when a preferred voice has been downloaded.
    ///
    /// A role keeps a preferred voice it has been given, but one standing in for a preferred voice,
    /// or no longer installed, is replaced with the role's voice now.
    func refresh(installedVoices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices()) {
        let selection = Self.selection(from: installedVoices)
        let availableSpeakers = Self.availableSpeakers(in: selection)
        self.availableSpeakers = availableSpeakers
        missingVoiceNames = selection.missing
        for role in voices.indices {
            let voice = voices[role]
            guard !selection.isPreferred(voice.voice) || !availableSpeakers.contains(voice) else { continue }
            voices[role] = selection.voice(forRole: role).map(Speaker.init) ?? availableSpeakers[role % availableSpeakers.count]
        }
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
