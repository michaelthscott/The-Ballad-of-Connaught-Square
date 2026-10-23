//
//  MIDIEventTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 23/10/2026.
//

import Testing
@testable import ConnaughtSquare

struct MIDIEventTests {

    @Test func testStatusBytes() {
        #expect(MIDIEvent.on.rawValue == 0x90)
        #expect(MIDIEvent.off.rawValue == 0x80)
    }

}
