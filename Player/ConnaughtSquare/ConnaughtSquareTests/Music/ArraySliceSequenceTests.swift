//
//  ArraySliceSequenceTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 05/12/2023.
//

import Testing
@testable import ConnaughtSquare

struct ArraySliceSequenceTests {

    @Test func testInit() async throws {
        let array = [1, 2, 3]
        #expect(ArraySliceSequence(array, width: 2).count == 2)
        #expect(ArraySliceSequence(array[...], width: 2).count == 2)
        #expect(array.slices(width: 2).count == 2)
        #expect(array[...].slices(width: 2).count == 2)
    }
    
    @Test func testSequence() async throws {
        #expect(ArraySliceSequence([], width: 0).isEmpty)
    }
    
    @Test func testCount() async throws {
        #expect([].slices(width: 0).count == 0)
        #expect([].slices(width: 1).count == 0)
        #expect([].slices(width: 2).count == 0)
        #expect([].slices(width: 9).count == 0)
        #expect([1].slices(width: 0).count == 0)
        #expect([1].slices(width: 1).count == 1)
        #expect([1].slices(width: 2).count == 0)
        #expect([1].slices(width: 9).count == 0)
        #expect([1, 2, 3].slices(width: 0).count == 0)
        #expect([1, 2, 3].slices(width: 1).count == 3)
        #expect([1, 2, 3].slices(width: 2).count == 2)
        #expect([1, 2, 3].slices(width: 3).count == 1)
        #expect([1, 2, 3].slices(width: 9).count == 0)
        #expect([1, 2, 3, 4, 5, 6, 7, 8, 9].slices(width: 0).count == 0)
        #expect([1, 2, 3, 4, 5, 6, 7, 8, 9].slices(width: 1).count == 9)
        #expect([1, 2, 3, 4, 5, 6, 7, 8, 9].slices(width: 2).count == 8)
        #expect([1, 2, 3, 4, 5, 6, 7, 8, 9].slices(width: 3).count == 7)
        #expect([1, 2, 3, 4, 5, 6, 7, 8, 9].slices(width: 9).count == 1)
    }
    
    @Test func testForLoop() async throws {
        let array = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        var slices: [ArraySlice<Int>] = []
        for slice in array.slices(width: 3) {
            slices.append(slice)
        }
        #expect(slices[0] == [1, 2, 3])
        #expect(slices[6] == [7, 8, 9])
        #expect(slices.count == 7)
    }
    
    @Test func testMap() async throws {
        let array = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        var slices = array.slices(width: 3).map { $0 }
        #expect(slices[0] == [1, 2, 3])
        #expect(slices[6] == [7, 8, 9])
        #expect(slices.count == 7)
        
        slices = array.slices(width: 1).map { $0 }
        #expect(slices[0] == [1])
        #expect(slices[8] == [9])
        #expect(slices.count == 9)
        
        slices = array.slices(width: 0).map { $0 }
        #expect(slices[0] == [])
        #expect(slices[8] == [])
        #expect(slices.count == 9)
        
        slices = array.slices(width: 9).map { $0 }
        #expect(slices[0] == [1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(slices.count == 1)
    }

}
