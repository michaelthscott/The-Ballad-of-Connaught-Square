//
//  Instrument.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 05/12/2023.
//

import AVFoundation

/// An instrument which can play notes.
///
/// An instrument is just a name: the sampler preset it refers to is loaded by the sound bank
/// when its notes are played, so creating an instrument has no audio side effects.
struct Instrument: Sendable {
    let name: InstrumentName

    /// Plays the note.
    /// - Parameters:
    ///   - note: A note.
    ///   - soundBank: The sound bank to play on.
    func play(note: Note, on soundBank: SoundBank = .shared) async {
        await soundBank.play(note: note)
    }

    /// Plays the notes for the specified time.
    /// - Parameters:
    ///   - notes: A sequence of notes.
    ///   - duration: A length of time.
    ///   - soundBank: The sound bank to play on.
    /// - Returns: The notes played.
    func play(notes: Cycle<Note>, duration: Duration, on soundBank: SoundBank = .shared) async -> [Note] {
        do {
            return try await soundBank.play(notes: notes, duration: duration, instrument: name)
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
}

extension Instrument: Equatable {
    static func == (lhs: Instrument, rhs: Instrument) -> Bool {
        lhs.name == rhs.name
    }
}

extension Instrument: CustomStringConvertible {
    var description: String {
        name.description
    }
}
