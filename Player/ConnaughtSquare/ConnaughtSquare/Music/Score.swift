//
//  Score.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 01/11/2026.
//

import Foundation

/// The score of a performance: the intermissions played before the ballad and between its cantos
/// and stanzas, and the interludes that open each line and part, played every time one begins.
///
/// Only the intermission for the largest division that begins is played, so the introduction
/// replaces the first canto's intermission, and a canto's intermission replaces its first stanza's.
/// After an intermission, the line's interlude opens the first part as it does every line.
struct Score: Sendable, Equatable {
    var title: String
    /// Played before the ballad.
    var introduction: Intermission
    /// Played before each later canto.
    var canto: Intermission
    /// Played before each later stanza of a canto.
    var stanza: Intermission
    /// Opens the first part of each line.
    var line: Interlude
    /// The interlude before each later part of a line.
    var part: Interlude

    /// The score in the app's assets.
    static let bundled: Score = {
        do {
            return try asset()
        } catch {
            fatalError("Failed to read the score: \(error)")
        }
    }()

    /// Reads a score written in Markdown in a data asset.
    /// - Throws: `AssetError.missing` if there's no such asset, or a `ScoreError` if it's written wrongly.
    static func asset(named name: String = "Score", from bundle: Bundle = .main) throws -> Score {
        try Score(markdown: String(decoding: assetData(name, from: bundle), as: UTF8.self))
    }

    /// Every intermission in the score, introduction first.
    var intermissions: [Intermission] {
        [introduction, canto, stanza]
    }

    /// Every interlude in the score, the line's first.
    var interludes: [Interlude] {
        [line, part]
    }

    /// Every distinct way the score selects notes, so that each can be prepared once.
    var noteSelections: Set<NoteSelection> {
        Set((intermissions.flatMap(\.tracks) + interludes.flatMap(\.tracks)).map(\.notes))
    }
}

/// Music played in full between divisions of the ballad, with nothing recited.
struct Intermission: Sendable, Equatable {
    var tracks: [Track]
    /// The length of the intermission. It lasts at least until its last stretch ends, and can
    /// rest after that.
    var seconds: Double

    init(tracks: [Track] = [], seconds: Double? = nil) {
        self.tracks = tracks
        let lastEnd = tracks.flatMap(\.stretches).compactMap { stretch -> Double? in
            guard case .seconds(let seconds) = stretch.end else { return nil }
            return seconds
        }.max() ?? 0
        self.seconds = max(seconds ?? 0, lastEnd)
    }

    /// The intermission as an interlude with no recitation, for arranging its events.
    var interlude: Interlude {
        Interlude(tracks: tracks)
    }
}

/// What happens when a line or part of the ballad begins: when the part starts being recited, and what
/// the instruments play around it. The part's turn ends once the recitation and every instrument
/// have finished.
struct Interlude: Sendable, Equatable {
    /// The seconds from the start of the interlude to the start of the recitation.
    var recitationStart: Double
    var tracks: [Track]

    init(recitationStart: Double = 0, tracks: [Track] = []) {
        self.recitationStart = recitationStart
        self.tracks = tracks
    }
}

/// Some instruments playing the same stretches of an interlude. Each instrument plays one unbroken
/// melody through all of them, so only its volume changes from one stretch to the next, and it
/// carries on where it left off after a gap.
struct Track: Sendable, Equatable {
    var instruments: [InstrumentName]
    var notes: NoteSelection
    /// The stretches in the order they're played, none overlapping the one before.
    var stretches: [Stretch]

    init(instruments: [InstrumentName], notes: NoteSelection = .standard, stretches: [Stretch]) {
        self.instruments = instruments
        self.notes = notes
        self.stretches = stretches
    }
}

/// A stretch of time an instrument plays for, at a volume.
struct Stretch: Sendable, Equatable {
    var start: Moment
    var end: Moment
    /// The volume from 0, silent, to 1, full. The velocity of each note is scaled by it, so the
    /// notes keep their varying dynamics, only softer.
    var volume: Double

    init(start: Moment, end: Moment, volume: Double = 1) {
        self.start = start
        self.end = end
        self.volume = volume
    }
}

/// A moment in an interlude, counted from its start or from the end of the recitation.
enum Moment: Sendable, Equatable {
    /// Seconds from the start of the interlude.
    case seconds(Double)
    /// Seconds after the recitation finishes.
    case afterRecitation(seconds: Double)

    /// As the recitation finishes.
    static let endOfRecitation = Moment.afterRecitation(seconds: 0)

    /// When the moment is expected, from the start of the interlude.
    /// - Parameter recitationEnd: When the recitation is expected to finish, from the start of the interlude.
    func expected(recitationEnd: Duration) -> Duration {
        switch self {
        case .seconds(let seconds):
            .seconds(seconds)
        case .afterRecitation(let seconds):
            recitationEnd + .seconds(seconds)
        }
    }

    /// Whether the moment is certainly before the other, whatever the length of the recitation.
    func isBefore(_ other: Moment) -> Bool {
        switch (self, other) {
        case (.seconds(let a), .seconds(let b)), (.afterRecitation(let a), .afterRecitation(let b)):
            a < b
        case (.seconds, .afterRecitation):
            true
        case (.afterRecitation, .seconds):
            false
        }
    }
}

extension Moment: CustomStringConvertible {
    /// The moment as it's written in a score, such as `5.5s`, `end` or `end+1s`.
    var description: String {
        switch self {
        case .seconds(let seconds):
            "\(seconds.formatted(.number.locale(Locale(identifier: "en_US_POSIX"))))s"
        case .afterRecitation(let seconds) where seconds == 0:
            "end"
        case .afterRecitation(let seconds):
            "end+\(Moment.seconds(seconds))"
        }
    }
}

extension Stretch: CustomStringConvertible {
    /// The stretch as it's written in a score, such as `5s–end+1s at 60%`.
    var description: String {
        let range = "\(start)–\(end)"
        return volume == 1 ? range : "\(range) at \((volume * 100).formatted(.number.locale(Locale(identifier: "en_US_POSIX"))))%"
    }
}

// MARK: - The standard score

extension Score {
    /// The score as the performance was first written: the string trio, followed by a second's rest,
    /// introduces the ballad, comes between its cantos and stanzas, and opens each line before its
    /// first part is recited.
    static let standard = Score(title: "The Ballad of Connaught Square",
                                introduction: Intermission(tracks: [.stringTrio(seconds: 13)], seconds: 14),
                                canto: Intermission(tracks: [.stringTrio(seconds: 11)], seconds: 12),
                                stanza: Intermission(tracks: [.stringTrio(seconds: 7)], seconds: 8),
                                line: Interlude(recitationStart: 6, tracks: [.stringTrio(seconds: 5)]),
                                part: Interlude(recitationStart: 1))
}

private extension Track {
    /// The violin, viola and cello play from the start for the seconds.
    static func stringTrio(seconds: Double) -> Track {
        Track(instruments: [.violin, .viola, .cello], stretches: [Stretch(start: .seconds(0), end: .seconds(seconds))])
    }
}
