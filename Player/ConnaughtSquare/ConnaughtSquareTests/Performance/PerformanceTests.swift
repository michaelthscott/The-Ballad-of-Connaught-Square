//
//  PerformanceTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 30/03/2025.
//

import Testing
@testable import ConnaughtSquare

@MainActor
struct PerformanceTests {

    @Test func testPerformance() async throws {
        let composer = Composer()
        let performance = Performance(composer: composer, ballad: Ballad(), speakers: Speakers())
        var events = EventsSequence(performance: performance)
        let firstBatch = events.next()
        let batch = try #require(firstBatch)
        #expect(batch.isEmpty == false)
    }

    @Test func testOrchestration() async throws {
        let performance = Performance(composer: Composer(), ballad: Ballad(), speakers: Speakers())
        let orchestration = performance.orchestration(duration: .seconds(1))
        #expect(orchestration.title == "The Ballad of Connaught Square")
        #expect(orchestration.assignments.count == 3)
    }

}
