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
	    
    @Test func testCurrentIndex() throws {
        #expect(cycle.currentIndex == cycle.elements.startIndex)
		_ = cycle.next()
		let copy = cycle!
        #expect(copy.currentIndex == cycle.elements.index(after: cycle.elements.startIndex))
	}

}
