//
//  MIDIEvent.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 12/01/2024.
//

import Foundation

/// MIDI events.
///
/// The raw values are the status bytes for channel 0. Note Off is `0x80` and Note On is `0x90`.
enum MIDIEvent: UInt8 {
	case on = 0b10010000
	case off = 0b10000000
}
