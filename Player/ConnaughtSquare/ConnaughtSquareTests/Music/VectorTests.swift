//
//  VectorTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 16/12/2023.
//

import Testing
@testable import ConnaughtSquare

struct VectorTests {

    @Test func testComparable() {
		// TODO: This needs to be more thought out and comprehensive.
        #expect(Vector<String>(["A"]) < Vector<String>(["A", "B"]))
        #expect(Vector<String>(["A", "B"]) == Vector<String>(["A", "B"]))
        #expect(Vector<String>(["A", "B"]) < Vector<String>(["A", "C"]))
        #expect(Vector<String>(["A", "B"]) < Vector<String>(["B", "C"]))
        #expect(Vector<String>(["A", "C"]) > Vector<String>(["A", "B"]))
        #expect(Vector<String>(["B", "C"]) > Vector<String>(["A", "B"]))
	}
	
    @Test func testSequence() {
		let empty: Vector<String> = []
		let notEmpty: Vector<String> = ["A"]
        #expect(empty.isEmpty)
        #expect(empty.count == 0)
        #expect(!notEmpty.isEmpty)
        #expect(notEmpty.count == 1)
		var iterator = notEmpty.makeIterator()
        #expect(iterator.next() == "A")
	}
	
    @Test func testCollection() {
		let empty: Vector<Int> = []
		let notEmpty: Vector<Int> = [1]
        #expect(empty.startIndex == empty.endIndex)
        #expect(notEmpty.startIndex == 0)
        #expect(notEmpty.endIndex == 1)
        #expect(notEmpty[0] == 1)
        #expect(notEmpty.index(after: 1) == 2)
	}
	
    @Test func testWeightedSet() {
		let set = WeightedSet<Vector<String>>([Vector<String>(["A", "B"], weight: 1), Vector<String>(["A", "B"], weight: 1), Vector<String>(["B", "C"], weight: 1)])
        #expect(set.count == 2)
        #expect(set[0] == Vector<String>(["A", "B"], weight: 1))
        #expect(set[1] == Vector<String>(["B", "C"], weight: 1))
	}

}
