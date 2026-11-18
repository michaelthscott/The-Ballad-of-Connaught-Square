//
//  CycleTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 19/01/2024.
//

import Testing
@testable import ConnaughtSquare

final class CycleTests {
    var cycle: Cycle<String>!

    init() throws {
        cycle = ["A", "B", "C"]
    }

    deinit {
        cycle = nil
    }
    
	@Test func testArrayLiteral() {
        #expect(cycle.elements == ["A", "B", "C"])
	}
	
    @Test func testNext() throws {
        #expect(cycle.next() == "A")
        #expect(cycle.next() == "B")
        #expect(cycle.next() == "C")
        #expect(cycle.next() == "A")
    }

    @Test func testStartingAt() {
        var cycle = Cycle(elements: ["A", "B", "C"], startingAt: 2)
        #expect(cycle.next() == "C")
        #expect(cycle.next() == "A")
        #expect(cycle.next() == "B")
    }
	    
    @Test func testCurrentIndex() throws {
        #expect(cycle.currentIndex == cycle.elements.startIndex)
		_ = cycle.next()
		let copy = cycle!
        #expect(copy.currentIndex == cycle.elements.index(after: cycle.elements.startIndex))
	}

    @Test func testMostFrequent() {
        let cycle: Cycle<String> = ["A", "B", "B", "C"]
        #expect(cycle.mostFrequent == "B")
    }

    @Test func testMostFrequentTieIsGreatest() {
        #expect(cycle.mostFrequent == "C")
    }

    @Test func testElementsByFrequency() {
        let cycle: Cycle<String> = ["A", "B", "B", "C", "C", "C"]
        #expect(cycle.elementsByFrequency == ["C", "B", "A"])
    }

    @Test func testElementsByFrequencyTiesAreGreatestFirst() {
        let cycle: Cycle<String> = ["A", "B", "B", "C", "D", "D"]
        #expect(cycle.elementsByFrequency == ["D", "B", "C", "A"])
        #expect(cycle.elementsByFrequency.first == cycle.mostFrequent)
    }

}
