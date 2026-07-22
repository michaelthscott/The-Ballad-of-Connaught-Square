//
//  EventTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/02/2024.
//

import Testing
@testable import ConnaughtSquare

struct EventTests {

    @Test func testInit() async throws {
        let instrument = Instrument(name: .accordion)
        let cycle = Cycle(elements: [Note(value: .a2, duration: .breve), Note(value: .a3, duration: .crotchet)])
        let assignment = Assignment(instrument: instrument, notes: cycle)
        let assignments: [Assignment] = [assignment]
        let orchestration: Orchestration = Orchestration(title: "Test", assignments: assignments)
        let event: Event = .play(orchestration: orchestration, duration: .seconds(1))
        #expect(event.description == "play(Test: 1.0 seconds)")
    }
}
