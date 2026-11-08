//
//  Event.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 17/01/2024.
//

import Foundation

/// An instrument playing through a cue: its melody, and the stretches of time it plays at each volume.
/// Events are `Sendable`, so they can be played off the main actor.
struct Event: Sendable {
    let instrument: Instrument
    /// The melody, played unbroken through every stretch. It repeats if the stretches last longer than it.
    let notes: Cycle<Note>
    let stretches: [Stretch]
}

extension Event: CustomStringConvertible {
    var description: String {
        "\(instrument): \(stretches.map(\.description).joined(separator: ", "))"
    }
}

/// Everything performed for one part of the ballad: any intermission played before it, when the
/// part starts being recited, what the instruments play around it, and the part and the speaker
/// who recites it.
struct Cue {
    /// Played in full before the rest of the cue starts.
    let intermission: [Event]
    /// The length of the intermission, which lasts at least as long as its events.
    let intermissionLength: Duration
    /// From the start of the cue to the start of the recitation.
    let recitationStart: Duration
    let events: [Event]
    let part: Part
    let speaker: Speaker
    /// Whether the part begins the ballad, so its title appears before anything else, even the intermission.
    var beginsBallad = false
    /// The rest after the ballad's title appears, before the intermission.
    var balladTitleRest: Duration = .zero
    /// The index of the canto the part begins, or `nil` if it doesn't begin a canto.
    var cantoIndex: Int? = nil
    /// The rest after the canto's title appears, before the rest of the cue starts.
    var cantoTitleRest: Duration = .zero
}

extension Cue: CustomStringConvertible {
    var description: String {
        "intermission(\(intermissionLength)): \(intermission.map(\.description).joined(separator: "; ")); \(events.map(\.description).joined(separator: "; ")); speak(\(speaker.name) at \(recitationStart): \(part.string))"
    }
}
