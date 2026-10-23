//
//  EventsSequence.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 10/04/2025.
//

import Foundation

/// Produces the batches of events that make up a performance, one batch per part of the ballad.
///
/// This is main-actor isolated because it reads the ballad and the speakers, so it can't conform
/// to `IteratorProtocol`; the performance drives it by calling `next()` directly.
@MainActor
struct EventsSequence {
    let performance: Performance
    var balladCursorSequence: BalladCursorSequence
    
    init(performance: Performance) {
        self.performance = performance
        balladCursorSequence = BalladCursorSequence(ballad: performance.ballad)
    }

    /// The events for the next part of the ballad, or `nil` once every part has been recited.
    mutating func next() -> [Event]? {
        guard let part = balladCursorSequence.currentPart else { return nil }
        var events: [Event] = []
        if balladCursorSequence.isStartOfBallad {
            events.append(.play(orchestration: performance.orchestration(duration: .seconds(13)), duration: .seconds(13)))
            events.append(.silence(duration: .seconds(1)))
        } else if balladCursorSequence.isStartOfCanto {
            events.append(.play(orchestration: performance.orchestration(duration: .seconds(11)), duration: .seconds(11)))
            events.append(.silence(duration: .seconds(1)))
        } else if balladCursorSequence.isStartOfStanza {
            events.append(.play(orchestration: performance.orchestration(duration: .seconds(7)), duration: .seconds(7)))
            events.append(.silence(duration: .seconds(1)))
        } else if balladCursorSequence.isStartOfLine {
            events.append(.play(orchestration: performance.orchestration(duration: .seconds(5)), duration: .seconds(5)))
            events.append(.silence(duration: .seconds(1)))
        } else if balladCursorSequence.remainingParts > 0 {
            events.append(.silence(duration: .seconds(1)))
        }
        events.append(.speak(part: part, speaker: performance.speakers.nextSpeaker))
        _ = balladCursorSequence.next()
        return events
    }
}
