//
//  Composer.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 05/12/2023.
//

/// A composer composes melodies from the patterns in its tunes.
struct Composer {
    /// The ways the tunes' patterns can be combined.
    enum SetOperation: String, CaseIterable, Sendable {
        case union
        case intersection
        case symmetricDifference
    }
    
    // TODO: We could treat vector width as a ceiling and reduce it until all the following functions return non-empty sets.
    // When we have more than two tunes, unions are accumulative. Symmetric differences are gradually accumulative, but can also be reductive. Intersections are gradually reductive.
    // What we currently do is to discard empty sets, these are more likely to occur with wider vectors because of the increasing difference between the elements.
    
    /// The non-empty sets made by combining the tunes in each of the operations, in the order of `SetOperation.allCases`.
    static func nonEmptyDurationSets(from tunes: [Tune], with vectorWidth: UInt, using operations: [SetOperation] = SetOperation.allCases) -> [NoteDurationVectors] {
        var array: [NoteDurationVectors] = []
        for operation in SetOperation.allCases where operations.contains(operation) {
            let set = durations(from: tunes, using: operation, with: vectorWidth)
            if !set.isEmpty {
                array.append(set)
            }
        }
        return array
    }
    
    /// The non-empty sets made by combining the tunes in each of the operations, in the order of `SetOperation.allCases`.
    static func nonEmptyIntervalSets(from tunes: [Tune], with vectorWidth: UInt, using operations: [SetOperation] = SetOperation.allCases) -> [NoteIntervalVectors] {
        var array: [NoteIntervalVectors] = []
        for operation in SetOperation.allCases where operations.contains(operation) {
            let set = intervals(from: tunes, using: operation, with: vectorWidth)
            if !set.isEmpty {
                array.append(set)
            }
        }
        return array
    }
    
    static func durations(from tunes: [Tune], using operation: SetOperation, with vectorWidth: UInt) -> NoteDurationVectors {
        guard let first = tunes.first else { return [] }
        return tunes.dropFirst().reduce(into: first.noteDurationVectors(width: vectorWidth)) { set, tune in
            switch operation {
            case .union:
                set.formUnion(tune.noteDurationVectors(width: vectorWidth))
            case .intersection:
                set.formIntersection(tune.noteDurationVectors(width: vectorWidth))
            case .symmetricDifference:
                set.formSymmetricDifference(tune.noteDurationVectors(width: vectorWidth))
            }
        }
    }
    
    static func intervals(from tunes: [Tune], using operation: SetOperation, with vectorWidth: UInt) -> NoteIntervalVectors {
        guard let first = tunes.first else { return [] }
        return tunes.dropFirst().reduce(into: first.noteIntervalVectors(width: vectorWidth)) { set, tune in
            switch operation {
            case .union:
                set.formUnion(tune.noteIntervalVectors(width: vectorWidth))
            case .intersection:
                set.formIntersection(tune.noteIntervalVectors(width: vectorWidth))
            case .symmetricDifference:
                set.formSymmetricDifference(tune.noteIntervalVectors(width: vectorWidth))
            }
        }
    }

    let tunes: [Tune]
    let vectorWidth: UInt
    let durations: [NoteDurationVectors]
    let intervals: [NoteIntervalVectors]

    init() {
        self.init(selection: .standard)
    }

    /// Creates a composer that selects notes as the score notates.
    init(selection: NoteSelection) {
        self.init(tunes: selection.tunes.map(\.tune), vectorWidth: selection.vectorWidth, operations: selection.operations)
    }
    
    init(tunes: [Tune], vectorWidth: UInt, operations: [SetOperation] = SetOperation.allCases) {
        self.tunes = tunes
        self.vectorWidth = vectorWidth
        durations = Self.nonEmptyDurationSets(from: tunes, with: vectorWidth, using: operations)
        intervals = Self.nonEmptyIntervalSets(from: tunes, with: vectorWidth, using: operations)
        // A score can ask for a combination with nothing in it, so say so now rather than when a note is first composed.
        precondition(!durations.isEmpty && !intervals.isEmpty, "No note patterns from \(tunes.map(\.title)) \(vectorWidth) wide using \(operations)")
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
    /// - Parameter generator: The random number generator to use.
    func randomDurationVector<T: RandomNumberGenerator>(using generator: inout T) -> NoteDurationVector {
        guard let randomDurations = durations.randomElement(using: &generator), let durationVector = randomDurations.weightedRandomElement(using: &generator) else {
            fatalError("Failed to get random duration vector")
        }
        return durationVector
    }

    /// Selects a random note interval vector.
    ///
    /// A set is chosen uniformly, then a vector is chosen from it in proportion to its weight, so vectors that occur more often in the tunes are more likely.
    /// - Parameter generator: The random number generator to use.
    func randomIntervalVector<T: RandomNumberGenerator>(using generator: inout T) -> NoteIntervalVector {
        guard let randomIntervals = intervals.randomElement(using: &generator), let intervalVector = randomIntervals.weightedRandomElement(using: &generator) else {
            fatalError("Failed to get random interval vector")
        }
        return intervalVector
    }

	/// The note each assignment starts from: the highest of the tunes' most frequent notes.
	let initialNote: Note

	/// The highest note across all the tunes.
	let ceilingNote: Note

	/// The lowest note across all the tunes, so that the range spans every tune as the ceiling does.
	let floorNote: Note

    /// Composes an assignment for the specified instrument and duration.
    ///
    /// The assignment opens on the pitch of the initial note, so every instrument begins in unison, then moves by intervals drawn from the tunes.
    /// - Parameters:
    ///   - instrument: An instrument.
    ///   - duration: A duration. Note that this should be sufficiently long to ensure that some notes are assigned.
    ///   - generator: The random number generator the patterns and dynamics are chosen with.
    /// - Returns: The assignment.
    func composeAssignment<T: RandomNumberGenerator>(instrument: Instrument, duration: Duration, using generator: inout T) -> Assignment {
        let openingDuration = randomDurationVector(using: &generator).first ?? initialNote.duration
        let opening = Note(value: initialNote.value, on: NoteVelocity.gaussianRandom(using: &generator), duration: openingDuration)
        var previousNote = opening
        var notes: [Note] = [opening]
        var currentDuration: Duration = openingDuration.microseconds
        while currentDuration < duration {
            for (interval, noteDuration) in zip(randomIntervalVector(using: &generator), randomDurationVector(using: &generator)) {
                let note = previousNote.nextNote(interval: interval, duration: noteDuration, ceiling: ceilingNote, floor: floorNote, using: &generator)
                notes.append(note)
                previousNote = note
                currentDuration += noteDuration.microseconds
            }
        }
        precondition(notes.count > 0, "No notes assigned to \(instrument)")
        return Assignment(instrument: instrument, notes: Cycle<Note>(elements: notes))
    }

    /// Composes an assignment for the specified instrument and duration, chosen with the system's random number generator.
    func composeAssignment(instrument: Instrument, duration: Duration) -> Assignment {
        var generator = SystemRandomNumberGenerator()
        return composeAssignment(instrument: instrument, duration: duration, using: &generator)
    }
}
