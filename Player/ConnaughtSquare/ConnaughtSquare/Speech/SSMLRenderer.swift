//
//  SSMLRenderer.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 11/11/2026.
//

import Foundation

/// Writes a declamation as Speech Synthesis Markup Language, so that a single utterance carries
/// every word's pitch and rate, the pauses, and any correct pronunciations.
///
/// Pitches and rates are written as percentages, relative to the voice's own, which SSML 1.1
/// allows for both. An utterance made from SSML ignores its `rate` and `pitchMultiplier`.
///
/// The declamation's rate is written once, around the whole part, and each word carries only its
/// pitch, with a rate of its own only where it's slower or faster than the rest. The voices follow
/// a rate around the whole part smoothly, but change a word's own rate in steps, 45% sounding the
/// same as 70%. A word's own rate replaces the part's rather than multiplying it.
enum SSMLRenderer {
    /// The SSML for the declamation, its pitches placed against the voice as its style says.
    /// - Parameters:
    ///   - declamation: The declamation.
    ///   - pace: What the declamation's rate is multiplied by, to bring the voice to the same pace as the others.
    static func ssml(for declamation: Declamation, pace: Float = 1) -> String {
        let baseRate = declamation.style.baseRate
        let words = zip(declamation.words, declamation.pitches).map { word, pitch in
            var text = escaped(word.text)
            if let ipa = word.ipa {
                text = "<phoneme alphabet=\"ipa\" ph=\"\(escaped(ipa))\">\(text)</phoneme>"
            }
            // A word's own rate replaces the part's rather than multiplying it, so it's written in full.
            let rate = abs(word.rate - baseRate) < 0.005 ? "" : " rate=\"\(percentage(rate: word.rate * pace))\""
            var element = "<prosody pitch=\"\(percentage(semitones: pitch))\"\(rate)>\(text)</prosody>"
            if word.pauseAfter > .zero {
                element += "<break time=\"\(milliseconds(word.pauseAfter))ms\"/>"
            }
            return element
        }
        let rate = percentage(rate: baseRate * pace)
        return "<speak><prosody rate=\"\(rate)\">\(words.joined(separator: " "))</prosody></speak>"
    }

    /// The change in frequency for a number of semitones, as a signed percentage.
    static func percentage(semitones: Double) -> String {
        let change = (pow(2, semitones / 12) - 1) * 100
        return change.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always(includingZero: true)).locale(Locale(identifier: "en_US_POSIX"))) + "%"
    }

    /// A rate relative to the voice's default, as a percentage.
    static func percentage(rate: Float) -> String {
        "\(Int((rate * 100).rounded()))%"
    }

    static func milliseconds(_ duration: Duration) -> Int {
        Int(duration.components.seconds * 1000 + duration.components.attoseconds / 1_000_000_000_000_000)
    }

    /// The text with the characters XML reserves escaped.
    static func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
