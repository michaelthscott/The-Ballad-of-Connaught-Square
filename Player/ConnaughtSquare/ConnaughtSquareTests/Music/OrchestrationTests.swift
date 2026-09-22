//
//  OrchestrationTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/02/2024.
//

import Testing
@testable import ConnaughtSquare

struct OrchestrationTests {
    let composer: Composer!
    let orchestration: Orchestration!
    
    init() async throws {
        composer = Composer()
        orchestration = composer.composeOrchestration("Connaught Square",
                                                      instruments: [Instrument(name: .violin), Instrument(name: .viola), Instrument(name: .cello)],
                                                      duration: .seconds(10))
    }
    
    @Test func testTitle() async throws {
        #expect(orchestration.title == "Connaught Square")
    }

    @Test func testPlay() async throws {
        await orchestration.play(duration: .seconds(10))
    }
    
}
