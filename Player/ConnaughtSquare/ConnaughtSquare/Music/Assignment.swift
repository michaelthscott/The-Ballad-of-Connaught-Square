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
}

extension Assignment: CustomStringConvertible {
    var description: String {
        "Assignment(\(instrument), \(notes))"
    }
}
