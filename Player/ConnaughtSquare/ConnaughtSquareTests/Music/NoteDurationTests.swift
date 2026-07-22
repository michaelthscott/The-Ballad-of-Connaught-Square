//
//  NoteDurationTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 19/01/2024.
//

import Testing
@testable import ConnaughtSquare

struct NoteDurationTests {

    @Test func testDuration() throws {
        #expect(NoteDuration.breve.duration == .seconds(8))
        #expect(NoteDuration.semibreve.duration == .seconds(4))
        #expect(NoteDuration.dottedMinim.duration == .seconds(3))
        #expect(NoteDuration.minim.duration == .seconds(2))
        #expect(NoteDuration.dottedCrotchet.duration == .seconds(1.5))
        #expect(NoteDuration.crotchet.duration == .seconds(1))
        #expect(NoteDuration.quaver.duration == .seconds(0.5))
    }
    
}
