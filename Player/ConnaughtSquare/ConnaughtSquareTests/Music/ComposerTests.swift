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
    
    @Test func testInitialNote() async throws {
        #expect(composer.floorNote <= composer.initialNote)
        #expect(composer.initialNote <= composer.ceilingNote)
    }

    @Test func testAssignmentsOpenOnTheInitialNote() throws {
        let orchestration = composer.composeOrchestration("Test",
                                                          instruments: [Instrument(name: .violin), Instrument(name: .viola), Instrument(name: .cello)],
                                                          duration: .seconds(10))
        for assignment in orchestration.assignments {
            let first = try #require(assignment.notes.elements.first)
            #expect(first.value == composer.initialNote.value)
        }
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

}
