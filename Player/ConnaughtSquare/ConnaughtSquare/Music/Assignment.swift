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
	/// - Parameter duration: The length of time to play the notes.
	func play(duration: Duration) -> [Note] {
        instrument.play(notes: notes, duration: duration)
	}
}

extension Assignment: CustomStringConvertible {
    var description: String {
        "Assignment(\(instrument), \(notes))"
    }
}
