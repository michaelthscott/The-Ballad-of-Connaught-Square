//
//  VoiceTurnsTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 01/11/2026.
//

import Testing
@testable import ConnaughtSquare

struct VoiceTurnsTests {
    func turns(_ rule: VoiceRule, roles: Int = 2) -> VoiceTurns {
        VoiceTurns(notation: VoiceNotation(roles: (0..<roles).map { "Role \($0)" }, rule: rule))
    }

    /// The roles take turns from the given role.
    @Test func testAlternate() {
        var turns = turns(.alternate(startingWith: 1), roles: 3)
        let roles = (0..<5).map { _ in turns.nextRole() }
        #expect(roles == [1, 2, 0, 1, 2])
    }

    /// A role outside the roles wraps around them.
    @Test func testRolesWrap() {
        var turns = turns(.alternate(startingWith: -1))
        let roles = (0..<3).map { _ in turns.nextRole() }
        #expect(roles == [1, 0, 1])
    }

    @Test func testNoRoles() {
        var turns = turns(.alternate(startingWith: 3), roles: 0)
        #expect(turns.nextRole() == 0)
    }
}
