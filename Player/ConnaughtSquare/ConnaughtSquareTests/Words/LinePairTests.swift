//
//  LinePairTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 30/12/2023.
//

import Foundation
import Testing
@testable import ConnaughtSquare

final class LinePairTests {
    var lines: [Line]!
    
    init() throws {
        lines = decodeAssets("Lines", from: Bundle(for: Line.self))
    }
    
    deinit {
        lines = nil
    }
    
    @Test func testAvailableRhymes() throws {
        let pair = LinePair(first: lines[0], second: lines[0])
        // TODO: Update when rhyme identification changes.
        let expected: [RhymeType] = [.single, .syllabic, .assonance, .consonance, .half, .pararhyme, .alliteration]
        #expect(pair.availableRhymes == expected)
    }
    
}
