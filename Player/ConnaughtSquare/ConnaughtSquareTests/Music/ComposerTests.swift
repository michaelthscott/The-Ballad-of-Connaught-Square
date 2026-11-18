//
//  ComposerTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 05/12/2023.
//

import Testing
@testable import ConnaughtSquare

struct ComposerTests {
	var composer: Composer
    
    init() async throws {
        composer = Composer() //(tunes: [Tune.randomTune(title: "A", length: 5), Tune.randomTune(title: "B", length: 5), Tune.randomTune(title: "C", length: 5)], vectorWidth: 2)
    }
    
    @Test func testInitialNotes() async throws {
        let notes = composer.initialNotes.elements
        #expect(notes.allSatisfy { composer.floorNote <= $0 && $0 <= composer.ceilingNote })
        #expect(Set(notes.map(\.value)).count == notes.count)
    }

    /// The initial notes run from the most to the least frequent pitch across all the tunes.
    @Test func testInitialNotesRunFromMostToLeastFrequent() {
        let values = composer.tunes.flatMap { $0.notes.elements.map(\.value) }
        let counts = composer.initialNotes.elements.map { note in values.filter { $0 == note.value }.count }
        #expect(counts == counts.sorted(by: >))
        #expect(Set(composer.initialNotes.elements.map(\.value)) == Set(values))
    }

    /// Each of an instrument's assignments opens on the next initial note in its own copy, starting again after the least frequent,
    /// whatever the other instruments are composed in between.
    @Test func testEachInstrumentOpensOnSuccessiveInitialNotes() throws {
        var composer = composer
        let values = composer.initialNotes.elements.map(\.value)
        let instruments = [InstrumentName.violin, .viola, .cello].map { Instrument(name: $0) }
        var openings: [InstrumentName: [NoteValue]] = [:]
        for _ in 0...values.count {
            for instrument in instruments {
                let assignment = composer.composeAssignment(instrument: instrument, duration: .seconds(10))
                let first = try #require(assignment.notes.elements.first)
                openings[instrument.name, default: []].append(first.value)
            }
        }
        for instrument in instruments {
            let opened = try #require(openings[instrument.name])
            let start = try #require(values.firstIndex(of: opened[0]))
            let expected = (0..<opened.count).map { values[(start + $0) % values.count] }
            #expect(opened == expected, "\(instrument.name)")
        }
    }

    /// Each instrument's copy of the initial notes starts at a random position.
    @Test func testInitialNotesStartAtRandomPositions() throws {
        var starts: Set<NoteValue> = []
        for seed in 0..<20 {
            var composer = composer
            var generator = SeededRandomNumberGenerator(seed: UInt64(seed))
            let assignment = composer.composeAssignment(instrument: Instrument(name: .viola), duration: .seconds(10), using: &generator)
            starts.insert(try #require(assignment.notes.elements.first).value)
        }
        #expect(starts.count > 1)
    }

    /// The same seed composes the same assignment, dynamics and all.
    @Test func testSeededAssignmentsRepeat() {
        var first = SeededRandomNumberGenerator(seed: 42)
        var second = SeededRandomNumberGenerator(seed: 42)
        let instrument = Instrument(name: .viola)
        var composer = composer
        var copy = composer
        let assignment = composer.composeAssignment(instrument: instrument, duration: .seconds(10), using: &first)
        let repeated = copy.composeAssignment(instrument: instrument, duration: .seconds(10), using: &second)
        #expect(assignment.notes.elements == repeated.notes.elements)
    }

    @Test func testRangeSpansAllTunes() {
        let low = Tune("Low", [Note(value: .d2, duration: .crotchet), Note(value: .g2, duration: .crotchet), Note(value: .g2, duration: .crotchet)])
        let high = Tune("High", [Note(value: .g2, duration: .crotchet), Note(value: .b3, duration: .crotchet), Note(value: .g2, duration: .crotchet)])
        let composer = Composer(tunes: [low, high], vectorWidth: 1)
        #expect(composer.floorNote.value == .d2)
        #expect(composer.ceilingNote.value == .b3)
    }
    
    @Test func testDurations() async throws {
        #expect(composer.durations.count <= Composer.SetOperation.allCases.count)
        let counts = composer.durations.reduce(into: []) { partialResult, set in
            partialResult.append(set.count)
        }
        #expect(counts == [24, 9, 15])
    }
    
    @Test func testIntervals() async throws {
        #expect(composer.intervals.count <= Composer.SetOperation.allCases.count)
        let counts = composer.intervals.reduce(into: []) { partialResult, set in
            partialResult.append(set.count)
        }
        #expect(counts == [52, 8, 44])
    }

    /// Describes a set as its vectors and weights, in order, so that any change to the set shows up.
    /// The order matters: `weightedRandomElement` walks the vectors in order.
    private func fingerprint<Element>(_ set: WeightedSet<Vector<Element>>, _ describe: (Element) -> String) -> String {
        set.elements.map { "\($0.elements.map(describe).joined(separator: ","))=\($0.weight)" }.joined(separator: " ")
    }

    private func short(_ interval: NoteInterval) -> String {
        switch interval {
        case .rising(let steps):
            "+\(steps)"
        case .falling(let steps):
            "-\(steps)"
        case .level:
            "0"
        }
    }

    /// Pins the union, intersection and symmetric difference of the built-in tunes' duration vectors,
    /// so that refactoring `WeightedSet` can't change the music unnoticed.
    @Test func testDurationSetsAreUnchanged() {
        let expected = [
            "Quaver,Quaver,Quaver=8 Quaver,Quaver,Crotchet=8 Quaver,Crotchet,Quaver=1 Quaver,Crotchet,Crotchet=8 Quaver,Crotchet,Dotted Minim=2 Crotchet,Quaver,Quaver=9 Crotchet,Crotchet,Quaver=5 Crotchet,Crotchet,Crotchet=12 Crotchet,Crotchet,Dotted Crotchet=3 Crotchet,Dotted Crotchet,Quaver=3 Crotchet,Dotted Minim,Crotchet=1 Dotted Crotchet,Quaver,Quaver=1 Dotted Crotchet,Quaver,Crotchet=3 Dotted Minim,Crotchet,Crotchet=1 Quaver,Quaver,Dotted Crotchet=1 Quaver,Quaver,Minim=1 Quaver,Quaver,Dotted Minim=2 Quaver,Dotted Crotchet,Quaver=1 Quaver,Minim,Crotchet=1 Quaver,Dotted Minim,Quaver=1 Crotchet,Crotchet,Minim=2 Crotchet,Minim,Crotchet=2 Minim,Crotchet,Quaver=3 Dotted Minim,Quaver,Quaver=1",
            "Quaver,Quaver,Quaver=8 Quaver,Quaver,Crotchet=8 Quaver,Crotchet,Crotchet=8 Crotchet,Quaver,Quaver=9 Crotchet,Crotchet,Quaver=5 Crotchet,Crotchet,Crotchet=12 Crotchet,Crotchet,Dotted Crotchet=3 Crotchet,Dotted Crotchet,Quaver=3 Dotted Crotchet,Quaver,Crotchet=3",
            "Quaver,Crotchet,Quaver=1 Quaver,Crotchet,Dotted Minim=2 Crotchet,Dotted Minim,Crotchet=1 Dotted Crotchet,Quaver,Quaver=1 Dotted Minim,Crotchet,Crotchet=1 Quaver,Quaver,Dotted Crotchet=1 Quaver,Quaver,Minim=1 Quaver,Quaver,Dotted Minim=2 Quaver,Dotted Crotchet,Quaver=1 Quaver,Minim,Crotchet=1 Quaver,Dotted Minim,Quaver=1 Crotchet,Crotchet,Minim=2 Crotchet,Minim,Crotchet=2 Minim,Crotchet,Quaver=3 Dotted Minim,Quaver,Quaver=1",
        ]
        #expect(composer.durations.map { fingerprint($0) { "\($0)" } } == expected)
    }

    /// Pins the union, intersection and symmetric difference of the built-in tunes' interval vectors.
    @Test func testIntervalSetsAreUnchanged() {
        let expected = [
            "+1,+2,0=2 +1,-1,-2=1 +1,-3,0=1 +2,+1,-1=1 +2,+2,-2=3 +2,-2,-2=2 +2,0,-2=2 +3,+2,+1=1 +4,+1,+2=1 +4,+3,+2=1 +5,+2,+2=3 +5,0,-2=1 -1,+1,-3=1 -1,-2,+5=1 -1,-2,-2=2 -1,-9,+5=1 -2,+4,+1=1 -2,+5,0=1 -2,-1,+1=4 -2,-1,-2=2 -2,-1,-9=1 -2,-2,+4=1 -3,-4,+4=1 -3,0,0=1 -4,+4,+3=1 -9,+5,+2=1 0,-2,-1=2 0,-3,-4=1 0,0,-3=1 +1,+2,-7=2 +1,+9,0=1 +2,+1,+2=2 +2,-2,+2=2 +2,-7,+4=2 +2,0,+2=1 +4,-2,-2=2 +5,-5,+5=2 +9,0,-2=1 -1,+1,+2=1 -1,+1,+9=1 -1,-4,0=1 -2,+2,+1=2 -2,+2,-2=1 -2,-1,-4=1 -2,-2,-1=5 -4,0,+5=1 -5,+5,+2=2 -7,+4,-2=2 0,+2,0=1 0,+5,-5=1 0,-2,+2=1 0,-2,-2=1",
            "+1,+2,0=2 +2,+2,-2=3 +2,-2,-2=2 +2,0,-2=2 +5,+2,+2=3 -1,-2,-2=2 -2,-1,+1=4 -2,-1,-2=2",
            "+1,-1,-2=1 +1,-3,0=1 +2,+1,-1=1 +3,+2,+1=1 +4,+1,+2=1 +4,+3,+2=1 +5,0,-2=1 -1,+1,-3=1 -1,-2,+5=1 -1,-9,+5=1 -2,+4,+1=1 -2,+5,0=1 -2,-1,-9=1 -2,-2,+4=1 -3,-4,+4=1 -3,0,0=1 -4,+4,+3=1 -9,+5,+2=1 0,-2,-1=2 0,-3,-4=1 0,0,-3=1 +1,+2,-7=2 +1,+9,0=1 +2,+1,+2=2 +2,-2,+2=2 +2,-7,+4=2 +2,0,+2=1 +4,-2,-2=2 +5,-5,+5=2 +9,0,-2=1 -1,+1,+2=1 -1,+1,+9=1 -1,-4,0=1 -2,+2,+1=2 -2,+2,-2=1 -2,-1,-4=1 -2,-2,-1=5 -4,0,+5=1 -5,+5,+2=2 -7,+4,-2=2 0,+2,0=1 0,+5,-5=1 0,-2,+2=1 0,-2,-2=1",
        ]
        #expect(composer.intervals.map { fingerprint($0, short) } == expected)
    }

    /// The standard selection composes as the default composer does.
    @Test func testStandardSelection() {
        let selected = Composer(selection: .standard)
        #expect(selected.durations == composer.durations)
        #expect(selected.intervals == composer.intervals)
    }

    /// A selection keeps only the sets for its operations, in the usual order, whatever order they're written in.
    @Test func testSelectionOperations() {
        let selected = Composer(selection: NoteSelection(operations: [.symmetricDifference, .intersection]))
        #expect(selected.durations == [composer.durations[1], composer.durations[2]])
        #expect(selected.intervals == [composer.intervals[1], composer.intervals[2]])
    }

    /// A selection can take its patterns from a single tune.
    @Test func testSelectionTunes() {
        let selected = Composer(selection: NoteSelection(tunes: [.theBritishGrenadiers], vectorWidth: 2, operations: [.union]))
        #expect(selected.tunes.map(\.title) == ["The British Grenadiers"])
        #expect(selected.vectorWidth == 2)
        #expect(selected.durations == [Tune.theBritishGrenadiers.noteDurationVectors(width: 2)])
    }

}
