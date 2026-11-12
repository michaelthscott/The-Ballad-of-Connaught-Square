//
//  RecordingSpeech.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 10/11/2026.
//

import Foundation
import AVFoundation
@testable import ConnaughtSquare

/// Stands in for the speech synthesizer, recording what it's asked to recite and when.
///
/// Each part takes the same length to "speak", slept at the performance's pause gate, so pausing
/// the performance holds the speech as it would real speech, and stopping it cancels the sleep.
@MainActor
final class RecordingSpeech: SpeechSynthesizing {
    struct Recitation: Equatable {
        /// The words recited, as the part's string.
        let string: String
        /// The part as it was to be recited.
        let declamation: Declamation
        let voice: String
        let pan: Float
        let volume: Float
        /// When the recitation started, on the clock.
        let start: ManualClock.Instant
    }

    /// How long each part takes to speak.
    let length: Duration
    private let clock: ManualClock
    private let gate: PauseGate
    private(set) var recitations: [Recitation] = []
    /// The identifiers of the voices warmed up, for each warm-up.
    private(set) var warmUps: [[String]] = []
    private(set) var stopCount = 0

    init(clock: ManualClock, gate: PauseGate, length: Duration = .seconds(2)) {
        self.clock = clock
        self.gate = gate
        self.length = length
    }

    func speak(_ declamation: Declamation, in voice: AVSpeechSynthesisVoice, pan: Float, volume: Float) async {
        recitations.append(Recitation(string: declamation.words.map(\.text).joined(separator: " "),
                                      declamation: declamation, voice: voice.identifier, pan: pan, volume: volume, start: clock.now))
        try? await gate.sleep(for: length)
    }

    func warmUp(_ voices: [AVSpeechSynthesisVoice]) {
        warmUps.append(voices.map(\.identifier))
    }

    // The performance pauses and resumes its gate itself, which holds the speech.
    func pause() {}

    func resume() {}

    func stop() {
        stopCount += 1
    }
}
