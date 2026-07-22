//
//  Instrument.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 05/12/2023.
//

import AVFoundation

/*
 TODO: Do we need to load the sound bank for each instrument?
 TODO: Is soundBankLoaded sufficient to prevent it being loaded multiple times?
 TODO: Do we need an AVAudioEngine for each instrument?
 TODO: Apple says that the sound bank should not be loaded on a real-time thread.
*/

/// An instrument which can play notes.
struct Instrument: Sendable {
    let name: InstrumentName
    
    init(name: InstrumentName) {
        self.name = name
        do {
            try SoundBank.shared.loadInstrument(name)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Plays the note.
    /// - Parameter note: A note.
	func play(note: Note) {
        SoundBank.shared.play(note: note)
	}
    
    /// Plays the notes for the specified time.
    /// - Parameters:
    ///   - notes: A sequence of notes.
    ///   - duration: A length of time.
    func play(notes: Cycle<Note>, duration: Duration) -> [Note] {
        var played: [Note] = []
        do {
            played = try SoundBank.shared.play(notes: notes, duration: duration)
        } catch {
            print(error.localizedDescription)
        }
        return played
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
