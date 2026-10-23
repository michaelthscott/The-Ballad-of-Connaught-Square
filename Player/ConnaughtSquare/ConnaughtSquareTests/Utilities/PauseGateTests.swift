//
//  PauseGateTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 23/10/2026.
//

import Testing
@testable import ConnaughtSquare

struct PauseGateTests {
    let clock = ContinuousClock()

    @Test func testWaitWhenOpen() async throws {
        let gate = PauseGate()
        #expect(gate.isPaused == false)
        await gate.wait()
    }

    @Test func testWaitUntilResumed() async throws {
        let gate = PauseGate()
        gate.pause()
        #expect(gate.isPaused)
        let waiting = Task { await gate.wait() }
        try await Task.sleep(for: .milliseconds(50))
        gate.resume()
        await waiting.value
        #expect(gate.isPaused == false)
    }

    @Test func testSleepWhenOpen() async throws {
        let gate = PauseGate()
        let elapsed = try await clock.measure {
            try await gate.sleep(for: .milliseconds(100))
        }
        #expect(elapsed >= .milliseconds(100))
        #expect(elapsed < .milliseconds(300))
    }

    @Test func testSleepExcludesTimePaused() async throws {
        let gate = PauseGate()
        let start = clock.now
        let sleeping = Task { try await gate.sleep(for: .milliseconds(200)) }
        // Pause part-way through the sleep, for longer than the sleep has left.
        try await Task.sleep(for: .milliseconds(100))
        gate.pause()
        try await Task.sleep(for: .milliseconds(300))
        gate.resume()
        try await sleeping.value
        let elapsed = clock.now - start
        #expect(elapsed >= .milliseconds(500))
        #expect(elapsed < .milliseconds(800))
    }

    @Test func testSleepThrowsWhenCancelled() async throws {
        let gate = PauseGate()
        let sleeping = Task { try await gate.sleep(for: .seconds(10)) }
        sleeping.cancel()
        await #expect(throws: CancellationError.self) {
            try await sleeping.value
        }
    }
}
