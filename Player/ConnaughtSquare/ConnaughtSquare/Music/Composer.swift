//
//  Composer.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 05/12/2023.
//

/// A composer composes an orchestration to be performed.
struct Composer {
    enum SetOperation: CaseIterable {
        case union
        case intersection
        case symmetricDifference
    }
    
    // TODO: We could treat vector width as a ceiling and reduce it until all the following functions return non-empty sets.
    // When we have more than two tunes, unions are accumulative. Symmetric differences are gradually accumulative, but can also be reductive. Intersections are gradually reductive.
    // What we currently do is to discard empty sets, these are more likely to occur with wider vectors because of the increasing difference between the elements.
    
    static func nonEmptyDurationSets(from tunes: [Tune], with vectorWidth: UInt) -> [NoteDurationVectors] {
        var array: [NoteDurationVectors] = []
        for operation in SetOperation.allCases {
            let set = durations(from: tunes, using: operation, with: vectorWidth)
            if !set.isEmpty {
                array.append(set)
            }
        }
        return array
    }
    
    static func nonEmptyIntervalSets(from tunes: [Tune], with vectorWidth: UInt) -> [NoteIntervalVectors] {
        var array: [NoteIntervalVectors] = []
        for operation in SetOperation.allCases {
            let set = intervals(from: tunes, using: operation, with: vectorWidth)
            if !set.isEmpty {
                array.append(set)
            }
        }
        return array
    }
    
    static func durations(from tunes: [Tune], using operation: SetOperation, with vectorWidth: UInt) -> NoteDurationVectors {
        guard let first = tunes.first else { return [] }
        return tunes.dropFirst().reduce(first.noteDurationVectors(width: vectorWidth)) { set, tune in
            switch operation {
            case .union:
                set.formUnion(tune.noteDurationVectors(width: vectorWidth))
            case .intersection:
                set.formIntersection(tune.noteDurationVectors(width: vectorWidth))
            case .symmetricDifference:
                set.formSymmetricDifference(tune.noteDurationVectors(width: vectorWidth))
            }
            return set
        }
    }
    
    static func intervals(from tunes: [Tune], using operation: SetOperation, with vectorWidth: UInt) -> NoteIntervalVectors {
        guard let first = tunes.first else { return [] }
        return tunes.dropFirst().reduce(first.noteIntervalVectors(width: vectorWidth)) { set, tune in
            switch operation {
            case .union:
                set.formUnion(tune.noteIntervalVectors(width: vectorWidth))
            case .intersection:
                set.formIntersection(tune.noteIntervalVectors(width: vectorWidth))
            case .symmetricDifference:
                set.formSymmetricDifference(tune.noteIntervalVectors(width: vectorWidth))
            }
            return set
        }
    }

    let tunes: [Tune]
    let vectorWidth: UInt
    let durations: [NoteDurationVectors]
    let intervals: [NoteIntervalVectors]

    init() {
        self.init(tunes: [Tune.theSashMyFatherWore, Tune.theBritishGrenadiers], vectorWidth: 3)
    }
    
    init(tunes: [Tune], vectorWidth: UInt) {
        self.tunes = tunes
        self.vectorWidth = vectorWidth
        durations = Self.nonEmptyDurationSets(from: tunes, with: vectorWidth)
        intervals = Self.nonEmptyIntervalSets(from: tunes, with: vectorWidth)
    }
    
    // TODO: An alternative approach might be to cycle through the durations and intervals and their vectors rather than randomly choosing them.
    // nextDurationVector
    // nextIntervalVector

    /// Selects a random note duration vector.
    var randomDurationVector: NoteDurationVector {
        guard let randomDurations = durations.randomElement(), let durationVector = randomDurations.randomElement() else {
            fatalError("Failed to get random duration vector")
        }
        return durationVector
    }
    
    /// Selects a random note interval vector.
    var randomIntervalVector: NoteIntervalVector {
        guard let randomIntervals = intervals.randomElement(), let intervalVector = randomIntervals.randomElement() else {
            fatalError("Failed to get random interval vector")
        }
        return intervalVector
    }
    
	// TODO: floor <= initial <= ceiling

	var initialNote: Note {
		guard let initial = tunes.compactMap({ $0.mostFrequentNote }).max(by: { lhs, rhs in lhs < rhs }) else {
			fatalError("Failed to find inital note")
		}
		return initial
	}
	
	var ceilingNote: Note {
		guard let ceiling = tunes.compactMap({ $0.highestNote }).max(by: { lhs, rhs in lhs < rhs }), initialNote <= ceiling else {
			fatalError("Failed to find highest note")
		}
		return ceiling
	}
	
	var floorNote: Note {
		guard let floor = tunes.compactMap({ $0.lowestNote }).max(by: { lhs, rhs in lhs < rhs }), floor <= initialNote else {
			fatalError("Failed to find lowest note")
		}
		return floor
	}
	
	// TODO: Variations for multiple instruments. Permutations of combinations of union, intersection and symmetric difference.
    
    /// Composes an orchestration for the specified instruments and duration.
    /// - Parameters:
    ///   - title: The title of the orchestration.
    ///   - instruments: A non empty array of instruments.
    ///   - duration: A duration. Note that this should be sufficiently long to ensure that some notes are assigned to the instruments.
    /// - Returns: The orchestration.
	func composeOrchestration(_ title: String, instruments: [Instrument], duration: Duration) -> Orchestration {
        precondition(instruments.count > 0, "No instruments specified")
        var assignments: [Assignment] = []
		for instrument in instruments {
            assignments.append(composeAssignment(instrument: instrument, duration: duration))
		}
		return Orchestration(title: title, assignments: assignments)
	}
    
    /// Composes an assignment for the specified instrument and duration.
    /// - Parameters:
    ///   - instrument: An instrument.
    ///   - duration: A duration. Note that this should be sufficiently long to ensure that some notes are assigned.
    /// - Returns: The assignment.
    func composeAssignment(instrument: Instrument, duration: Duration) -> Assignment {
        var previousNote = initialNote
        var notes: [Note] = []
        var currentDuration: Duration = .microseconds(0)
        while currentDuration < duration {
            for (interval, duration) in zip(randomIntervalVector, randomDurationVector) {
                let note = previousNote.nextNote(interval: interval, duration: duration, ceiling: ceilingNote, floor: floorNote)
                notes.append(note)
                previousNote = note
                currentDuration += duration.microseconds
            }
        }
        precondition(notes.count > 0, "No notes assigned to \(instrument)")
        return Assignment(instrument: instrument, notes: Cycle<Note>(elements: notes))
    }
}
