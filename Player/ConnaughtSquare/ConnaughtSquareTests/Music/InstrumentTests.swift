//
//  InstrumentTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 05/12/2023.
//

import Testing
@testable import ConnaughtSquare

final class InstrumentTests {
    @Test func testName() {
        #expect(Instrument(name: .clarinet).name == .clarinet)
    }

    @Test func testInstruments() {
        #expect(Instrument(name: .clarinet).name == .clarinet)
        #expect(Instrument(name: .bassoon).name == .bassoon)
    }
}
