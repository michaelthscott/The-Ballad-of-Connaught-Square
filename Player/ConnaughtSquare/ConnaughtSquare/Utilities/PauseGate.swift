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
///
/// The gate times its sleeps and pauses against a clock, the continuous clock unless it's given
/// another, such as a test clock that only moves on when told to.
final class PauseGate: Sendable {
    private struct State {
        /// The tasks waiting at the gate, keyed so that a cancelled task can remove its own.
        var waiters: [Int: CheckedContinuation<Void, Never>] = [:]
        var nextWaiterID = 0
        /// How long after the gate was made the current pause began, or `nil` if the gate is open.
        var pausedSince: Duration?
        /// The total length of every pause that has ended.
        var pausedTotal: Duration = .zero

        var isPaused: Bool { pausedSince != nil }

        /// The total time spent paused up to the given time since the gate was made, including any
        /// pause still in progress.
        func pausedTime(at instant: Duration) -> Duration {
            guard let pausedSince else { return pausedTotal }
            return pausedTotal + (instant - pausedSince)
        }
    }

    /// The time since the gate was made, on its clock.
    private let elapsed: @Sendable () -> Duration
    /// Sleeps for the duration on the gate's clock.
    private let sleepOnClock: @Sendable (Duration) async throws -> Void
    private let state = Mutex(State())

    /// Creates an open gate that times against the clock.
    init<C: Clock<Duration>>(clock: C = ContinuousClock()) {
        // The clock is kept behind closures, so the gate's type doesn't depend on it.
        let origin = clock.now
        elapsed = { origin.duration(to: clock.now) }
        sleepOnClock = { try await clock.sleep(for: $0) }
    }

    var isPaused: Bool {
        state.withLock { $0.isPaused }
    }

    // The clock is read under the lock so that racing calls to `pause()` and `resume()` can't
    // record a pause that ends before it began.

    func pause() {
        state.withLock { state in
            if state.pausedSince == nil {
                state.pausedSince = elapsed()
            }
        }
    }

    /// Opens the gate, releasing every task waiting at it.
    func resume() {
        let waiters = state.withLock { state in
            if let pausedSince = state.pausedSince {
                state.pausedTotal += elapsed() - pausedSince
                state.pausedSince = nil
            }
            defer { state.waiters = [:] }
            return state.waiters.values
        }
        for waiter in waiters {
            waiter.resume()
        }
    }

    /// Returns immediately if the gate is open, otherwise once it is resumed or the task is cancelled.
    ///
    /// This doesn't throw when the task is cancelled, so callers should check for cancellation afterwards.
    func wait() async {
        guard isPaused else { return }
        let id = state.withLock { state in
            defer { state.nextWaiterID += 1 }
            return state.nextWaiterID
        }
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                // The gate may have been resumed since the check above, so check again under the lock.
                // Checking for cancellation under the lock too means that either the task was already
                // cancelled here, or the cancellation handler runs later and finds the waiter.
                let isOpen = state.withLock { state in
                    if state.isPaused && !Task.isCancelled {
                        state.waiters[id] = continuation
                        return false
                    }
                    return true
                }
                if isOpen {
                    continuation.resume()
                }
            }
        } onCancel: {
            state.withLock { $0.waiters.removeValue(forKey: id) }?.resume()
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
            let start = elapsed()
            let pausedAtStart = state.withLock { $0.pausedTime(at: start) }
            try await sleepOnClock(remaining)
            let end = elapsed()
            let pausedAtEnd = state.withLock { $0.pausedTime(at: end) }
            remaining -= (end - start) - (pausedAtEnd - pausedAtStart)
        }
    }
}
