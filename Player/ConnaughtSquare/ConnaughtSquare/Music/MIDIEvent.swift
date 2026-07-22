//
//  MIDIEvent.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 12/01/2024.
//

import Foundation

/// MIDI events.
enum MIDIEvent: UInt8 {
	case on = 0b10000000
	case off = 0b10010000
}
