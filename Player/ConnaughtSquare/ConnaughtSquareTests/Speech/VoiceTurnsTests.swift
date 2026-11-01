//
//  VoiceTurnsTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 01/11/2026.
//

import Testing
@testable import ConnaughtSquare

struct VoiceTurnsTests {
    let part = Part(speaker: 0, string: "The cat sat on the mat.")

    func turns(_ rule: VoiceRule, roles: Int = 2) -> VoiceTurns {
        VoiceTurns(notation: VoiceNotation(roles: (0..<roles).map { "Role \($0)" }, rule: rule))
    }

    /// The roles take turns from the given role, whatever the parts' positions in their lines.
    @Test func testAlternate() {
        var turns = turns(.alternate(startingWith: 1), roles: 3)
        let roles = (0..<5).map { _ in turns.role(for: part, at: 0) }
        #expect(roles == [1, 2, 0, 1, 2])
    }

    /// Parts later than those listed take the last role.
    @Test func testByPartIndex() {
        var turns = turns(.byPartIndex(roles: [1, 0]))
        let roles = (0..<4).map { turns.role(for: part, at: $0) }
        #expect(roles == [1, 0, 0, 0])
    }

    @Test func testByPartIndexWithoutRoles() {
        var turns = turns(.byPartIndex(roles: []))
        #expect(turns.role(for: part, at: 2) == 0)
    }

    /// The written speaker wraps around the roles.
    @Test func testAsWritten() {
        var turns = turns(.asWritten)
        #expect(turns.role(for: Part(speaker: 1, string: "A"), at: 0) == 1)
        #expect(turns.role(for: Part(speaker: 2, string: "B"), at: 0) == 0)
    }

    @Test func testRolesWrap() {
        var turns = turns(.byPartIndex(roles: [-1, 5]))
        #expect(turns.role(for: part, at: 0) == 1)
        #expect(turns.role(for: part, at: 1) == 1)
    }

    @Test func testNoRoles() {
        var turns = turns(.alternate(startingWith: 3), roles: 0)
        #expect(turns.role(for: part, at: 0) == 0)
    }
}
