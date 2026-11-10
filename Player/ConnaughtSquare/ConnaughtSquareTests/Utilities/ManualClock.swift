//
//  ManualClock.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 10/11/2026.
//

import Foundation
import Synchronization

/// A clock whose time only moves on when a test advances it, so that timing can be checked
/// exactly and without waiting.
///
/// Advancing the clock wakes its sleepers in order of their deadlines, and lets each one carry on
/// to its next sleep before time moves past it.
final class ManualClock: Clock, Sendable {
    struct Instant: InstantProtocol {
        /// The time since the clock was made.
        var offset: Duration

        func advanced(by duration: Duration) -> Instant {
            Instant(offset: offset + duration)
        }

        func duration(to other: Instant) -> Duration {
            other.offset - offset
        }

        static func < (lhs: Instant, rhs: Instant) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    private struct Sleeper {
        let deadline: Instant
        let continuation: CheckedContinuation<Void, any Error>
    }

    private struct State {
        var now = Instant(offset: .zero)
        /// The tasks sleeping on the clock, keyed so that a cancelled task can remove its own.
        var sleepers: [Int: Sleeper] = [:]
        var nextSleeperID = 0
    }

    private let state = Mutex(State())

    var now: Instant {
        state.withLock { $0.now }
    }

    var minimumResolution: Duration {
        .zero
    }

    /// Suspends until the clock has been advanced to the deadline.
    /// - Throws: `CancellationError` if the task is cancelled.
    func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
        let id = state.withLock { state in
            defer { state.nextSleeperID += 1 }
            return state.nextSleeperID
        }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                // Checking for cancellation under the lock means that either the task was already
                // cancelled here, or the cancellation handler runs later and finds the sleeper.
                let result: Result<Void, any Error>? = state.withLock { state in
                    if Task.isCancelled {
                        return .failure(CancellationError())
                    }
                    if deadline <= state.now {
                        return .success(())
                    }
                    state.sleepers[id] = Sleeper(deadline: deadline, continuation: continuation)
                    return nil
                }
                if let result {
                    continuation.resume(with: result)
                }
            }
        } onCancel: {
            state.withLock { $0.sleepers.removeValue(forKey: id) }?.continuation.resume(throwing: CancellationError())
        }
    }

    /// Moves the clock on by the duration, waking each sleeper as its deadline is reached.
    func advance(by duration: Duration) async {
        let target = now.advanced(by: duration)
        await settle()
        while wakeNextSleepers(until: target) {
            await settle()
        }
        state.withLock { $0.now = max($0.now, target) }
    }

    /// Runs the work, moving the clock on to each deadline in turn whenever the work is waiting
    /// on the clock, until it finishes.
    /// - Returns: How far the clock moved on while the work ran.
    func measure(_ work: @escaping @Sendable () async -> Void) async -> Duration {
        let start = now
        let finished = Finished()
        let task = Task {
            await work()
            finished.set()
        }
        while !finished.isSet {
            await settle()
            guard !finished.isSet else { break }
            _ = wakeNextSleepers(until: nil)
        }
        await task.value
        return start.duration(to: now)
    }

    /// Waits until the sleepers stop changing, so that tasks woken or started elsewhere have had
    /// the chance to reach their next sleep.
    ///
    /// The tasks run on other threads and actors, so this pauses briefly in real time between checks.
    func settle() async {
        var last = sleeperIDs
        var unchangedChecks = 0
        while unchangedChecks < 5 {
            try? await Task.sleep(for: .milliseconds(1))
            let current = sleeperIDs
            if current == last {
                unchangedChecks += 1
            } else {
                unchangedChecks = 0
                last = current
            }
        }
    }

    private var sleeperIDs: Set<Int> {
        state.withLock { Set($0.sleepers.keys) }
    }

    /// Moves the clock to the earliest deadline, unless it's after the limit, and wakes the sleepers due then.
    /// - Returns: Whether any sleepers were woken.
    private func wakeNextSleepers(until limit: Instant?) -> Bool {
        let due = state.withLock { state -> [CheckedContinuation<Void, any Error>] in
            guard let next = state.sleepers.values.map(\.deadline).min() else { return [] }
            if let limit, limit < next { return [] }
            state.now = max(state.now, next)
            let ids = state.sleepers.filter { $0.value.deadline <= next }.map(\.key)
            return ids.compactMap { state.sleepers.removeValue(forKey: $0)?.continuation }
        }
        for continuation in due {
            continuation.resume()
        }
        return !due.isEmpty
    }
}

/// Whether some work has finished, which any task can check.
private final class Finished: Sendable {
    private let state = Mutex(false)

    var isSet: Bool {
        state.withLock { $0 }
    }

    func set() {
        state.withLock { $0 = true }
    }
}
