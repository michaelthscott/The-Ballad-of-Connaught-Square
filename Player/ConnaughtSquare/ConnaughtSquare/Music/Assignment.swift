//
//  Assignment.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 24/01/2024.
//

import Foundation

/// An assignment of an instrument to play a cycle of notes.
struct Assignment: Sendable {
	let instrument: Instrument
	let notes: Cycle<Note>
	
	init(instrument: Instrument, notes: Cycle<Note>) {
		self.instrument = instrument
		self.notes = notes
	}
	
	/// Play the notes on the instruments for the specified duration.
	/// - Parameters:
	///   - duration: The length of time to play the notes.
	///   - soundBank: The sound bank to play on.
	/// - Returns: The notes played.
	func play(duration: Duration, on soundBank: SoundBank = .shared) async -> [Note] {
        await instrument.play(notes: notes, duration: duration, on: soundBank)
	}
}

extension Assignment: CustomStringConvertible {
    var description: String {
        "Assignment(\(instrument), \(notes))"
    }
}
