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
    /// - Parameters:
    ///   - interlude: An interlude of the score.
    ///   - partDuration: The expected length of the part recited in the interlude.
    func events(for interlude: Interlude, partDuration: Duration) -> [Event] {
        let recitationEnd = .seconds(interlude.recitationStart) + partDuration
        return interlude.tracks.flatMap { track in
            let duration = track.stretches.reduce(Duration.zero) { total, stretch in
                total + max(stretch.end.expected(recitationEnd: recitationEnd) - stretch.start.expected(recitationEnd: recitationEnd), .zero)
            }
            return track.instruments.map { name in
                let instrument = Instrument(name: name)
                let assignment = composer(for: track.notes).composeAssignment(instrument: instrument, duration: duration)
                return Event(instrument: instrument, notes: assignment.notes, stretches: track.stretches)
            }
        }
    }

    private func composer(for selection: NoteSelection) -> Composer {
        composers[selection] ?? Composer(selection: selection)
    }
}
