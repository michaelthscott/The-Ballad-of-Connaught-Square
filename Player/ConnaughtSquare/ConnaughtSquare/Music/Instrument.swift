//
//  Instrument.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 05/12/2023.
//

/// An instrument which can play notes.
///
/// An instrument is just a name: the sampler preset it refers to is loaded by the sound bank
/// when its notes are played, so creating an instrument has no audio side effects.
struct Instrument: Sendable {
    let name: InstrumentName
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
