//
//  PauseGate.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 23/10/2026.
//

import Foundation
import Synchronization

/// A gate that tasks wait at while it is paused.
///
/// Pausing takes effect immediately and synchronously, so a caller on any actor can pause the gate
/// and know that nothing will pass it until it is resumed.
final class PauseGate: Sendable {
    private struct State {
        var waiters: [CheckedContinuation<Void, Never>] = []
        /// When the current pause began, or `nil` if the gate is open.
        var pausedSince: ContinuousClock.Instant?
        /// The total length of every pause that has ended.
        var pausedTotal: Duration = .zero

        var isPaused: Bool { pausedSince != nil }

        /// The total time spent paused up to the given instant, including any pause still in progress.
        func pausedTime(at instant: ContinuousClock.Instant) -> Duration {
            guard let pausedSince else { return pausedTotal }
            return pausedTotal + (instant - pausedSince)
        }
    }

    private let clock = ContinuousClock()
    private let state = Mutex(State())

    var isPaused: Bool {
        state.withLock { $0.isPaused }
    }

    func pause() {
        let now = clock.now
        state.withLock { state in
            if state.pausedSince == nil {
                state.pausedSince = now
            }
        }
    }

    /// Opens the gate, releasing every task waiting at it.
    func resume() {
        let now = clock.now
        let waiters = state.withLock { state in
            if let pausedSince = state.pausedSince {
                state.pausedTotal += now - pausedSince
                state.pausedSince = nil
            }
            defer { state.waiters = [] }
            return state.waiters
        }
        for waiter in waiters {
            waiter.resume()
        }
    }

    /// Returns immediately if the gate is open, otherwise once it is resumed.
    func wait() async {
        guard isPaused else { return }
        await withCheckedContinuation { continuation in
            // The gate may have been resumed since the check above, so check again under the lock.
            let isOpen = state.withLock { state in
                if state.isPaused {
                    state.waiters.append(continuation)
                    return false
                }
                return true
            }
            if isOpen {
                continuation.resume()
            }
        }
    }

    /// Suspends for the given duration of time during which the gate is open.
    ///
    /// Time spent paused doesn't count, so a note that is paused part-way through sounds for the
    /// rest of its length once the gate is resumed. Each sleep runs for the time still to go; on
    /// waking, any time that was paused during it is added back and slept off after the gate reopens.
    /// - Throws: `CancellationError` if the task is cancelled.
    func sleep(for duration: Duration) async throws {
        var remaining = duration
        while remaining > .zero {
            await wait()
            try Task.checkCancellation()
            let start = clock.now
            let pausedAtStart = state.withLock { $0.pausedTime(at: start) }
            try await Task.sleep(for: remaining)
            let end = clock.now
            let pausedAtEnd = state.withLock { $0.pausedTime(at: end) }
            remaining -= (end - start) - (pausedAtEnd - pausedAtStart)
        }
    }
}
