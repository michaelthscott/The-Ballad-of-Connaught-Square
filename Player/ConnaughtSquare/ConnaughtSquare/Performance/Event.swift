//
//  Event.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 17/01/2024.
//

import Foundation

/// A stretch of accompaniment. Events are `Sendable`, so they can be played off the main actor.
enum Event: Sendable {
    case play(orchestration: Orchestration, duration: Duration)
    /// Plays until the part has been recited.
    case accompany(orchestration: Orchestration)
    case silence(duration: Duration)
}

extension Event: CustomStringConvertible {
    var description: String {
        switch self {
        case .play(let orchestration, let duration):
            return "play(\(orchestration.title): \(duration))"
        case .accompany(let orchestration):
            return "accompany(\(orchestration.title))"
        case .silence(let duration):
            return "silence(\(duration))"
        }
    }
}

/// Everything performed for one part of the ballad: the accompaniment played before the part is
/// recited, the accompaniment played under it, and the part and the speaker who recites it.
struct Cue {
    let before: [Event]
    let under: [Event]
    let part: Part
    let speaker: Speaker
}

extension Cue: CustomStringConvertible {
    var description: String {
        "before: \(before), under: \(under), speak(\(speaker.name): \(part.string))"
    }
}
