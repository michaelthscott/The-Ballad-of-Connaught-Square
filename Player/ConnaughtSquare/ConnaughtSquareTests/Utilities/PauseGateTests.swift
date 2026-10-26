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

    @Test func testWaitReturnsWhenCancelled() async throws {
        let gate = PauseGate()
        gate.pause()
        let waiting = Task { await gate.wait() }
        try await Task.sleep(for: .milliseconds(50))
        waiting.cancel()
        await waiting.value
        // Cancelling a waiter releases only that waiter, not the gate.
        #expect(gate.isPaused)
    }

    @Test func testWaitReturnsWhenAlreadyCancelled() async throws {
        let gate = PauseGate()
        gate.pause()
        let waiting = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await gate.wait()
        }
        await waiting.value
        #expect(gate.isPaused)
    }

    @Test func testSleepThrowsWhenCancelledWhilePaused() async throws {
        let gate = PauseGate()
        gate.pause()
        let sleeping = Task { try await gate.sleep(for: .seconds(10)) }
        try await Task.sleep(for: .milliseconds(50))
        sleeping.cancel()
        await #expect(throws: CancellationError.self) {
            try await sleeping.value
        }
    }

    @Test func testSleepWhenOpen() async throws {
        let gate = PauseGate()
        let elapsed = try await clock.measure {
            try await gate.sleep(for: .milliseconds(100))
        }
        #expect(elapsed >= .milliseconds(100))
        // Only guards against hanging: sleeps can wake late while other tests run in parallel.
        #expect(elapsed < .seconds(1))
    }

    @Test func testSleepExcludesTimePaused() async throws {
        let gate = PauseGate()
        let start = clock.now
        let sleeping = Task { try await gate.sleep(for: .milliseconds(200)) }
        // Pause part-way through the sleep, for longer than the sleep has left.
        try await Task.sleep(for: .milliseconds(100))
        gate.pause()
        try await Task.sleep(for: .seconds(1))
        gate.resume()
        try await sleeping.value
        let elapsed = clock.now - start
        // 100 ms before the pause, 1 s paused, then the 100 ms left.
        #expect(elapsed >= .milliseconds(1200))
        // Counting the pause twice would take about 2.2 s. The long pause leaves room below that for
        // sleeps that wake late while other tests run in parallel.
        #expect(elapsed < .seconds(2))
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
