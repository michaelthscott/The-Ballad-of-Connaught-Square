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
	/// - Parameter duration: The length of time to play.
	func play(duration: Duration) {
        //TODO: How can we collect and return the notes played?
        DispatchQueue.concurrentPerform(iterations: assignments.count) { index in
            let played = assignments[index].play(duration: duration)
            print("\(assignments[index].instrument.name): \(played)")
        }
	}
}
