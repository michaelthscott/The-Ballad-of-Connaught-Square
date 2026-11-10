//
//  Arranger.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 01/11/2026.
//

/// Turns the score's interludes into events, composing a melody for each instrument.
struct Arranger {
    let title: String
    /// A composer for each way the score selects notes. Composers take a while to prepare, so they
    /// are prepared once, up front.
    private let composers: [NoteSelection: Composer]

    init(score: Score) {
        title = score.title
        var composers: [NoteSelection: Composer] = [:]
        for selection in score.noteSelections {
            composers[selection] = Composer(selection: selection)
        }
        self.composers = composers
    }

    /// The events that play the interlude, one for each instrument of each track.
    ///
    /// Each instrument's melody is composed for as long as its stretches are expected to last, taking
    /// the part as long as it's expected to take to recite. The melody repeats if they last longer.
    /// An instrument in a track that continues carries on its melody from the part before instead.
    /// - Parameters:
    ///   - interlude: An interlude of the score.
    ///   - partDuration: The expected length of the part recited in the interlude.
    ///   - melodies: Where each instrument's melody stopped in the part before.
    ///   - generator: The random number generator the melodies are composed with.
    func events<T: RandomNumberGenerator>(for interlude: Interlude, partDuration: Duration, continuing melodies: [InstrumentName: Cycle<Note>] = [:], using generator: inout T) -> [Event] {
        let recitationEnd = .seconds(interlude.recitationStart) + partDuration
        var events: [Event] = []
        for track in interlude.tracks {
            let duration = track.stretches.reduce(Duration.zero) { total, stretch in
                total + max(stretch.end.expected(recitationEnd: recitationEnd) - stretch.start.expected(recitationEnd: recitationEnd), .zero)
            }
            for name in track.instruments {
                let instrument = Instrument(name: name)
                if track.continues, let melody = melodies[name] {
                    events.append(Event(instrument: instrument, notes: melody, stretches: track.stretches))
                    continue
                }
                let assignment = composer(for: track.notes).composeAssignment(instrument: instrument, duration: duration, using: &generator)
                events.append(Event(instrument: instrument, notes: assignment.notes, stretches: track.stretches))
            }
        }
        return events
    }

    /// The events that play the interlude, composed with the system's random number generator.
    func events(for interlude: Interlude, partDuration: Duration, continuing melodies: [InstrumentName: Cycle<Note>] = [:]) -> [Event] {
        var generator = SystemRandomNumberGenerator()
        return events(for: interlude, partDuration: partDuration, continuing: melodies, using: &generator)
    }

    private func composer(for selection: NoteSelection) -> Composer {
        composers[selection] ?? Composer(selection: selection)
    }
}
