//
//  EventsSequence.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 10/04/2025.
//

import Foundation

struct EventsSequence: Sequence, IteratorProtocol {
    typealias Element = [Event]
    let performance: Performance
    var balladCursorSequence: BalladCursorSequence
    
    init(performance: Performance) {
        self.performance = performance
        balladCursorSequence = BalladCursorSequence(ballad: performance.ballad)
    }

    mutating func next() -> [Event]? {
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
        events.append(.speak(part: balladCursorSequence.currentPart, speaker: performance.speakers.nextSpeaker))
        _ = balladCursorSequence.next()
        return events
    }
}
