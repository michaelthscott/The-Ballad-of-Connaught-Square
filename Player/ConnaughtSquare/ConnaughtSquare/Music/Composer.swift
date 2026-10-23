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
            if !set.weightedElements.isEmpty {
                array.append(set)
            }
        }
        return array
    }
    
    static func nonEmptyIntervalSets(from tunes: [Tune], with vectorWidth: UInt) -> [NoteIntervalVectors] {
        var array: [NoteIntervalVectors] = []
        for operation in SetOperation.allCases {
            let set = intervals(from: tunes, using: operation, with: vectorWidth)
            if !set.weightedElements.isEmpty {
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
        // These are fixed by the tunes, so work them out once rather than for every note composed.
        guard let initial = tunes.map(\.mostFrequentNote).max() else {
            fatalError("Failed to find inital note")
        }
        guard let ceiling = tunes.map(\.highestNote).max(), initial <= ceiling else {
            fatalError("Failed to find highest note")
        }
        guard let floor = tunes.map(\.lowestNote).min(), floor <= initial else {
            fatalError("Failed to find lowest note")
        }
        initialNote = initial
        ceilingNote = ceiling
        floorNote = floor
    }
    
    // TODO: An alternative approach might be to cycle through the durations and intervals and their vectors rather than randomly choosing them.
    // nextDurationVector
    // nextIntervalVector

    /// Selects a random note duration vector.
    ///
    /// A set is chosen uniformly, then a vector is chosen from it in proportion to its weight, so vectors that occur more often in the tunes are more likely.
    var randomDurationVector: NoteDurationVector {
        guard let randomDurations = durations.randomElement(), let durationVector = randomDurations.weightedRandomElement() else {
            fatalError("Failed to get random duration vector")
        }
        return durationVector
    }

    /// Selects a random note interval vector.
    ///
    /// A set is chosen uniformly, then a vector is chosen from it in proportion to its weight, so vectors that occur more often in the tunes are more likely.
    var randomIntervalVector: NoteIntervalVector {
        guard let randomIntervals = intervals.randomElement(), let intervalVector = randomIntervals.weightedRandomElement() else {
            fatalError("Failed to get random interval vector")
        }
        return intervalVector
    }
    
	// TODO: floor <= initial <= ceiling

	/// The note each assignment starts from: the highest of the tunes' most frequent notes.
	let initialNote: Note

	/// The highest note across all the tunes.
	let ceilingNote: Note

	/// The lowest note across all the tunes, so that the range spans every tune as the ceiling does.
	let floorNote: Note

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
    ///
    /// The assignment opens on the pitch of the initial note, so every instrument begins in unison, then moves by intervals drawn from the tunes.
    /// - Parameters:
    ///   - instrument: An instrument.
    ///   - duration: A duration. Note that this should be sufficiently long to ensure that some notes are assigned.
    /// - Returns: The assignment.
    func composeAssignment(instrument: Instrument, duration: Duration) -> Assignment {
        let openingDuration = randomDurationVector.first ?? initialNote.duration
        let opening = Note(value: initialNote.value, on: NoteVelocity.gaussianRandom(), off: NoteVelocity.gaussianRandom(), duration: openingDuration)
        var previousNote = opening
        var notes: [Note] = [opening]
        var currentDuration: Duration = openingDuration.microseconds
        while currentDuration < duration {
            for (interval, noteDuration) in zip(randomIntervalVector, randomDurationVector) {
                let note = previousNote.nextNote(interval: interval, duration: noteDuration, ceiling: ceilingNote, floor: floorNote)
                notes.append(note)
                previousNote = note
                currentDuration += noteDuration.microseconds
            }
        }
        precondition(notes.count > 0, "No notes assigned to \(instrument)")
        return Assignment(instrument: instrument, notes: Cycle<Note>(elements: notes))
    }
}
