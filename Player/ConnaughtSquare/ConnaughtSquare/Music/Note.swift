//
//  Note.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 05/12/2023.
//

/// A music note.
struct Note: Sendable {
    static func randomNote() -> Note {
        Note(value: NoteValue.randomValue, duration: NoteDuration.randomDuration)
    }

    let value: NoteValue
    /// The velocity the note starts with. There's no release velocity, as the sampler doesn't take one when a note stops.
    let on: NoteVelocity
    let duration: NoteDuration

    init(value: NoteValue, on: NoteVelocity = .mp, duration: NoteDuration) {
        self.value = value
        self.on = on
        self.duration = duration
    }
    
    func nextNote(interval nextInterval: NoteInterval, duration nextDuration: NoteDuration, ceiling: Note, floor: Note) -> Note {
        var nextValue = 0
        switch nextInterval {
        case .rising(let by):
            nextValue = min(Int(value.rawValue) + by, Int(ceiling.value.rawValue))
        case .falling(let by):
            nextValue = max(Int(value.rawValue) - by, Int(floor.value.rawValue))
        case .level:
            nextValue = Int(value.rawValue)
        }
        guard let nextNoteValue = NoteValue(rawValue: UInt8(nextValue)) else {
            fatalError("Undefined note value: \(nextValue)")
        }
        return Note(value: nextNoteValue, on: NoteVelocity.gaussianRandom(), duration: nextDuration)
    }
}

extension Note: Comparable {
    static func < (lhs: Note, rhs: Note) -> Bool {
        lhs.value < rhs.value
    }
}

extension Note: Hashable {
	
}

extension Note: CustomStringConvertible {
    var description: String {
        "\(value) \(duration)"
    }
}
