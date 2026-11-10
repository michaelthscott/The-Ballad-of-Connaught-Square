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
        let string: String
        let voice: String
        let pan: Float
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

    func speak(_ attributedString: NSAttributedString, in voice: AVSpeechSynthesisVoice, pan: Float) async {
        recitations.append(Recitation(string: attributedString.string, voice: voice.identifier, pan: pan, start: clock.now))
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
