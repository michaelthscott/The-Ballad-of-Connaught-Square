//
//  EventTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/02/2024.
//

import Testing
@testable import ConnaughtSquare

struct EventTests {

    @Test func testDescription() async throws {
        let cycle = Cycle(elements: [Note(value: .a2, duration: .breve), Note(value: .a3, duration: .crotchet)])
        let event = Event(instrument: Instrument(name: .viola),
                          notes: cycle,
                          stretches: [Stretch(start: .seconds(0), end: .seconds(5)),
                                      Stretch(start: .seconds(5), end: .afterRecitation(seconds: 1), volume: 0.6)])
        #expect(event.description == "Viola: 0s–5s, 5s–end+1s at 60%")
    }
}
