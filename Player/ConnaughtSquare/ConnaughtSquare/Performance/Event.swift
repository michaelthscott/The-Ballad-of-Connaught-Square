//
//  Event.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 17/01/2024.
//

import Foundation

enum Event {
	case speak(part: Part, speaker: Speaker)
    case play(orchestration: Orchestration, duration: Duration)
	case silence(duration: Duration)
}

extension Event: CustomStringConvertible {
	var description: String {
		switch self {
		case .speak(let part, let speaker):
			return "speak(\(speaker.name): \(part.string))"
		case .play(let orchestration, let duration):
			return "play(\(orchestration.title): \(duration))"
		case .silence(let duration):
			return "silence(\(duration))"
        }
	}
}
