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

}
