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
    /// The melodies are composed with a copy of the performance's random number generator, so a
    /// seeded generator composes the same music for every sequence of the performance.
    private var generator: AnyRandomNumberGenerator

    init(performance: Performance) {
        self.performance = performance
        balladCursorSequence = BalladCursorSequence(ballad: performance.ballad)
        voiceTurns = VoiceTurns(notation: VoiceNotation(roles: performance.speakers.roles))
        generator = AnyRandomNumberGenerator(performance.randomNumberGenerator)
    }

    /// The cue for the next part of the ballad, or `nil` once every part has been recited.
    /// - Parameter melodies: Where each instrument's melody stopped in the part before, for the
    ///   instruments that continue theirs. An intermission starts them all afresh.
    mutating func next(continuing melodies: [InstrumentName: Cycle<Note>] = [:]) -> Cue? {
        guard let part = balladCursorSequence.currentPart else { return nil }
        let intermission = currentIntermission
        let interlude = currentInterlude
        let arranger = performance.arranger
        let role = voiceTurns.nextRole()
        let isStartOfBallad = balladCursorSequence.isStartOfBallad
        let isStartOfCanto = balladCursorSequence.isStartOfCanto
        var intermissionEvents: [Event] = []
        if let intermission {
            intermissionEvents = arranger.events(for: intermission.interlude, partDuration: .zero, using: &generator)
        }
        let events = arranger.events(for: interlude, partDuration: part.duration,
                                     continuing: intermission == nil ? melodies : [:], using: &generator)
        let cue = Cue(intermission: intermissionEvents,
                      intermissionLength: .seconds(intermission?.seconds ?? 0),
                      recitationStart: .seconds(interlude.recitationStart),
                      events: events,
                      part: part,
                      speaker: performance.speakers.speaker(forRole: role),
                      pan: performance.speakers.pan(forRole: role),
                      beginsBallad: isStartOfBallad,
                      balladTitleRest: isStartOfBallad ? .seconds(performance.score.balladTitleRest) : .zero,
                      cantoIndex: isStartOfCanto ? balladCursorSequence.cursor?.cantoIndex : nil,
                      cantoTitleRest: isStartOfCanto ? .seconds(performance.score.cantoTitleRest) : .zero)
        _ = balladCursorSequence.next()
        return cue
    }

    /// The introduction before the ballad, or the intermission after the canto or stanza that ends
    /// before the current part, the canto's taking the place of the stanza's,
    /// or `nil` if the part doesn't begin a stanza.
    private var currentIntermission: Intermission? {
        let score = performance.score
        if balladCursorSequence.isStartOfBallad {
            return score.introduction
        } else if balladCursorSequence.isStartOfCanto {
            return score.canto
        } else if balladCursorSequence.isStartOfStanza {
            return score.stanza
        } else {
            return nil
        }
    }

    /// The interlude that opens the current part: the stanza's first line's if it begins a stanza,
    /// the line's if it begins a later line, otherwise the part's.
    private var currentInterlude: Interlude {
        let score = performance.score
        if balladCursorSequence.isStartOfStanza {
            return score.firstLine
        } else if balladCursorSequence.isStartOfLine {
            return score.line
        } else {
            return score.part
        }
    }
}
