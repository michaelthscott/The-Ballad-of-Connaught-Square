//
//  Orchestration.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 24/01/2024.
//

import Foundation

/// An orchestration is a titled instrumentation.
struct Orchestration: Sendable {
	let title: String
    let assignments: [Assignment]

	init(title: String, assignments: [Assignment]) {
		self.title = title
        self.assignments = assignments
	}
	
	/// Play the instrumentation for the specified duration.
	///
	/// The assignments play concurrently, each in its own child task, so cancelling the
	/// surrounding task stops all of them.
	/// - Parameters:
	///   - duration: The length of time to play.
	///   - soundBank: The sound bank to play on.
	func play(duration: Duration, on soundBank: SoundBank = .shared) async {
        //TODO: How can we collect and return the notes played? A task group can now return them.
        await withDiscardingTaskGroup { group in
            for assignment in assignments {
                group.addTask {
                    let played = await assignment.play(duration: duration, on: soundBank)
                    print("\(assignment.instrument.name): \(played)")
                }
            }
        }
	}
}
