//
//  NoteIntervalTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/02/2024.
//

import Testing
@testable import ConnaughtSquare

struct NoteIntervalTests {

    @Test func testLevel() {
        #expect(NoteInterval(from: Note(value: .a2, duration: .breve), to: Note(value: .a2, duration: .breve)) == .level)
    }
}
