//
//  Arranger.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 01/11/2026.
//

/// Turns the score's segments into events, composing an orchestration for each passage of music.
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

    /// Composes the passage for the duration, giving each instrument notes selected as the score notates.
    /// Notes composed for the duration repeat if the passage plays for longer.
    func orchestration(for passage: Passage, lasting duration: Duration) -> Orchestration {
        let assignments = passage.instruments.map { part in
            composer(for: part.notes).composeAssignment(instrument: Instrument(name: part.instrument), duration: duration, volume: part.volume)
        }
        return Orchestration(title: title, assignments: assignments)
    }

    /// The event that performs the segment, or `nil` if there's nothing to perform.
    /// - Parameters:
    ///   - segment: A segment of the score.
    ///   - partDuration: The expected length of the part the segment plays under, or `nil` before the part.
    ///     A passage that lasts as long as the part is composed for this length, and is left out before the part.
    func event(for segment: Segment, under partDuration: Duration?) -> Event? {
        switch segment {
        case .music(let passage):
            switch (passage.duration, partDuration) {
            case (let duration?, _) where passage.instruments.isEmpty:
                // An orchestration without assignments would finish at once, so this is a rest of the same length.
                .silence(duration: duration)
            case (let duration?, _):
                .play(orchestration: orchestration(for: passage, lasting: duration), duration: duration)
            case (nil, let partDuration?) where !passage.instruments.isEmpty:
                .accompany(orchestration: orchestration(for: passage, lasting: partDuration))
            case (nil, _):
                nil
            }
        case .rest(let seconds):
            .silence(duration: .seconds(seconds))
        }
    }

    private func composer(for selection: NoteSelection) -> Composer {
        composers[selection] ?? Composer(selection: selection)
    }
}
