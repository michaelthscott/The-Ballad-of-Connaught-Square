//
//  EventsSequence.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 10/04/2025.
//

import Foundation

/// Produces the cues that make up a performance, one cue per part of the ballad, as the score notates them.
///
/// This is main-actor isolated because it reads the ballad and the speakers, so it can't conform
/// to `IteratorProtocol`; the performance drives it by calling `next()` directly.
@MainActor
struct EventsSequence {
    let performance: Performance
    var balladCursorSequence: BalladCursorSequence
    /// The voices' turns start afresh with each sequence, and so with each performance.
    private var voiceTurns: VoiceTurns

    init(performance: Performance) {
        self.performance = performance
        balladCursorSequence = BalladCursorSequence(ballad: performance.ballad)
        voiceTurns = VoiceTurns(notation: performance.score.voices)
    }

    /// The cue for the next part of the ballad, or `nil` once every part has been recited.
    mutating func next() -> Cue? {
        guard let part = balladCursorSequence.currentPart, let cursor = balladCursorSequence.cursor else { return nil }
        let interlude = currentInterlude
        let arranger = performance.arranger
        let role = voiceTurns.role(at: cursor.partIndex)
        let cue = Cue(before: interlude.before.compactMap { arranger.event(for: $0, under: nil) },
                      under: interlude.under.compactMap { arranger.event(for: $0, under: part.duration) },
                      part: part,
                      speaker: performance.speakers.speaker(forRole: role))
        _ = balladCursorSequence.next()
        return cue
    }

    /// The interlude for the largest division of the ballad that begins with the current part.
    private var currentInterlude: Interlude {
        let score = performance.score
        if balladCursorSequence.isStartOfBallad {
            return score.introduction
        } else if balladCursorSequence.isStartOfCanto {
            return score.canto
        } else if balladCursorSequence.isStartOfStanza {
            return score.stanza
        } else if balladCursorSequence.isStartOfLine {
            return score.line
        } else {
            return score.part
        }
    }
}
