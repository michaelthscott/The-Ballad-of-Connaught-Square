//
//  VoiceSelection.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 11/11/2026.
//

import AVFoundation

/// What choosing the voices needs to know about a voice, so that tests can describe voices that
/// aren't installed.
protocol VoiceDescription: Equatable {
    var name: String { get }
    var language: String { get }
    var quality: AVSpeechSynthesisVoiceQuality { get }
}

extension AVSpeechSynthesisVoice: VoiceDescription {}

/// The voices the ballad can be recited in, chosen from those installed.
///
/// The ballad is recited by the enhanced downloads of particular voices, which speak the marked-up
/// recitation smoothly. The compact voices sound rough, and the Eloquence voices, such as Eddy,
/// break the recitation into a phrase for every word. While any of the preferred voices isn't
/// installed, the other voices in the language are offered in its place, the same voice's smaller
/// downloads first, so that the ballad can still be recited.
struct VoiceSelection<Voice: VoiceDescription> {
    /// The voices to recite in, one for each role in turn, by name.
    let preferredNames: [String]
    /// The preferred voices that are installed, in the order of their names, followed by the
    /// voices offered in place of any that aren't.
    let available: [Voice]
    /// The names of the preferred voices that aren't installed in enhanced quality or better.
    let missing: [String]

    init(installed: [Voice], preferredNames: [String], language: String) {
        self.preferredNames = preferredNames
        let inLanguage = installed.filter { $0.language == language }
        var preferred: [Voice] = []
        var missing: [String] = []
        for name in preferredNames {
            // The best quality wins, so a premium download is preferred to an enhanced one.
            if let best = inLanguage.filter({ Self.isPreferred($0, named: name) }).max(by: { $0.quality.rawValue < $1.quality.rawValue }) {
                preferred.append(best)
            } else {
                missing.append(name)
            }
        }
        let others = missing.isEmpty ? [] : inLanguage.filter { !preferred.contains($0) }.sorted { lhs, rhs in
            let lhsStandsIn = missing.contains(Self.baseName(of: lhs.name))
            let rhsStandsIn = missing.contains(Self.baseName(of: rhs.name))
            if lhsStandsIn != rhsStandsIn { return lhsStandsIn }
            if lhs.quality != rhs.quality { return lhs.quality.rawValue > rhs.quality.rawValue }
            return lhs.name < rhs.name
        }
        self.available = preferred + others
        self.missing = missing
    }

    /// The voice's name without its quality: "Daniel" for "Daniel (Enhanced)".
    static func baseName(of name: String) -> String {
        name.components(separatedBy: " (").first ?? name
    }

    /// Whether the voice is the named voice in enhanced quality or better.
    static func isPreferred(_ voice: Voice, named name: String) -> Bool {
        baseName(of: voice.name) == name && voice.quality.rawValue >= AVSpeechSynthesisVoiceQuality.enhanced.rawValue
    }

    /// Whether the voice is one of the preferred voices.
    func isPreferred(_ voice: Voice) -> Bool {
        preferredNames.contains { Self.isPreferred(voice, named: $0) }
    }

    /// The voice the role recites in unless another is chosen: the role's preferred voice, or the
    /// same voice in a smaller download in its place, or else the available voices in turn. The
    /// roles take the preferred names in turn, starting again after the last. `nil` when no voice
    /// is available.
    func voice(forRole role: Int) -> Voice? {
        guard !available.isEmpty else { return nil }
        let turn = (role % available.count + available.count) % available.count
        guard !preferredNames.isEmpty else { return available[turn] }
        let name = preferredNames[(role % preferredNames.count + preferredNames.count) % preferredNames.count]
        return available.first { Self.isPreferred($0, named: name) }
            ?? available.first { Self.baseName(of: $0.name) == name }
            ?? available[turn]
    }
}
