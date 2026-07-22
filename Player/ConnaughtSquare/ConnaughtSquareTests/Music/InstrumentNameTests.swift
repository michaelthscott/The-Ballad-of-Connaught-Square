//
//  InstrumentNameTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/02/2024.
//

import Testing
@testable import ConnaughtSquare

struct InstrumentNameTests {

    @Test func testInit() {
        let name: InstrumentName = .accordion
        #expect(name.description == "Accordion")
    }
}
