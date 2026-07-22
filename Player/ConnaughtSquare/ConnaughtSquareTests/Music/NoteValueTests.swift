//
//  NoteValueTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/02/2024.
//

import Testing
@testable import ConnaughtSquare

struct NoteValueTests {

    @Test func testNoteValue() {
        #expect(NoteValue.randomValue.rawValue != 0)
    }
}
