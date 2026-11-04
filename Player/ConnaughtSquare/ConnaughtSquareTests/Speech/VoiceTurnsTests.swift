//
//  VoiceTurnsTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 01/11/2026.
//

import Testing
@testable import ConnaughtSquare

struct VoiceTurnsTests {
    func turns(roles: Int) -> VoiceTurns {
        VoiceTurns(notation: VoiceNotation(roles: (0..<roles).map { "Role \($0)" }))
    }

    /// The roles take turns from the first, going back to it after the last.
    @Test func testTakeTurns() {
        var turns = turns(roles: 3)
        let roles = (0..<5).map { _ in turns.nextRole() }
        #expect(roles == [0, 1, 2, 0, 1])
    }

    @Test func testNoRoles() {
        var turns = turns(roles: 0)
        #expect(turns.nextRole() == 0)
        #expect(turns.nextRole() == 0)
    }
}
