//
//  PerformanceTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 30/03/2025.
//

import Testing
@testable import ConnaughtSquare

struct PerformanceTests {

    @Test func testPerformance() async throws {
        let composer = Composer()
        let performance = Performance(composer: composer, ballad: Ballad(), speakers: Speakers())
        #expect(performance.eventsArray.isEmpty == false)
    }

}
