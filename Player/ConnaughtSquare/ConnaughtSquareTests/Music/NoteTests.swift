//
//  NoteTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 05/12/2023.
//

import Testing
@testable import ConnaughtSquare

struct NoteTests {

    @Test func testInit() {
        let note = Note(value: .c3, duration: .crotchet)
        #expect(note.value == NoteValue.c3)
    }

    @Test func testNoteInterval() {
        let note1 = Note(value: .c3, duration: .crotchet)
        let note2 = Note(value: .d3, duration: .crotchet)
        #expect(NoteInterval(from: note1, to: note2) == .rising(by: 2))
        #expect(NoteInterval(from: note2, to: note1) == .falling(by: 2))
        #expect(NoteInterval(from: note1, to: note1) == .level)
    }

}
