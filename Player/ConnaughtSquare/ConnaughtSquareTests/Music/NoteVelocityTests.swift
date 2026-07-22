//
//  NoteVelocityTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/02/2024.
//

import Testing
@testable import ConnaughtSquare

struct NoteVelocityTests {

    @Test func testNoteVelocity() async throws {
        #expect(NoteVelocity.random().rawValue != 0)
    }
    
}
