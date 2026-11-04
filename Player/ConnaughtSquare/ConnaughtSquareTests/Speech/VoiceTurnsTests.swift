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

    /// The roles take turns from the given role, whatever the parts' positions in their lines.
    @Test func testAlternate() {
        var turns = turns(.alternate(startingWith: 1), roles: 3)
        let roles = (0..<5).map { _ in turns.role(at: 0) }
        #expect(roles == [1, 2, 0, 1, 2])
    }

    /// Parts later than those listed take the last role.
    @Test func testByPartIndex() {
        var turns = turns(.byPartIndex(roles: [1, 0]))
        let roles = (0..<4).map { turns.role(at: $0) }
        #expect(roles == [1, 0, 0, 0])
    }

    @Test func testByPartIndexWithoutRoles() {
        var turns = turns(.byPartIndex(roles: []))
        #expect(turns.role(at: 2) == 0)
    }

    @Test func testRolesWrap() {
        var turns = turns(.byPartIndex(roles: [-1, 5]))
        #expect(turns.role(at: 0) == 1)
        #expect(turns.role(at: 1) == 1)
    }

    @Test func testNoRoles() {
        var turns = turns(.alternate(startingWith: 3), roles: 0)
        #expect(turns.role(at: 0) == 0)
    }
}
