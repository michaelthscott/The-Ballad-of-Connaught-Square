//
//  Score.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 01/11/2026.
//

import Foundation

/// The score of a performance: an introduction, and the interludes that open each canto, stanza,
/// line and part, played every time one begins. It also notates the voices that recite the parts.
///
/// Only the interlude for the largest division that begins is played, so the opening of a canto
/// replaces the openings of its first stanza, line and part. The introduction stands in for the
/// first canto's interlude.
struct Score: Codable, Sendable, Equatable {
    var title: String
    var voices: VoiceNotation
    var introduction: Interlude
    var canto: Interlude
    var stanza: Interlude
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

    /// Every interlude in the score, introduction first.
    var interludes: [Interlude] {
        [introduction, canto, stanza, line, part]
    }

    /// Every distinct way the score selects notes, so that each can be prepared once.
    var noteSelections: Set<NoteSelection> {
        var selections: Set<NoteSelection> = []
        for interlude in interludes {
            for segment in interlude.before + interlude.under {
                if case .music(let passage) = segment {
                    selections.formUnion(passage.instruments.map(\.notes))
                }
            }
        }
        return selections
    }
}

/// What plays when a division of the ballad begins.
struct Interlude: Sendable, Equatable {
    /// Played in full before the part is recited.
    var before: [Segment]
    /// Starts as the part is recited. The part's turn ends once both have finished.
    var under: [Segment]

    init(before: [Segment] = [], under: [Segment] = []) {
        self.before = before
        self.under = under
    }
}

extension Interlude: Codable {
    enum CodingKeys: String, CodingKey {
        case before, under
    }

    /// Either list may be left out of the score, meaning nothing plays then.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        before = try container.decodeIfPresent([Segment].self, forKey: .before) ?? []
        under = try container.decodeIfPresent([Segment].self, forKey: .under) ?? []
    }
}

/// A stretch of an interlude: a passage of music, or a rest.
enum Segment: Sendable, Equatable {
    case music(Passage)
    case rest(seconds: Double)
}

extension Segment: Codable {
    enum CodingKeys: String, CodingKey {
        case music, rest
    }

    /// Written as `{ "music": { … } }` or `{ "rest": 1 }`, rather than the synthesised form,
    /// which would nest the passage under `_0` and the rest under `seconds`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let passage = try container.decodeIfPresent(Passage.self, forKey: .music) {
            self = .music(passage)
        } else if let seconds = try container.decodeIfPresent(Double.self, forKey: .rest) {
            self = .rest(seconds: seconds)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                    debugDescription: "A segment must be either \"music\" or \"rest\"."))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .music(let passage):
            try container.encode(passage, forKey: .music)
        case .rest(let seconds):
            try container.encode(seconds, forKey: .rest)
        }
    }
}

/// A passage of music played by some instruments together, for a number of seconds or, without
/// them, for as long as the part takes to recite.
///
/// A passage without seconds plays only under the part; one before the part is left out.
struct Passage: Codable, Sendable, Equatable {
    var seconds: Double?
    var instruments: [InstrumentPart]

    init(seconds: Double? = nil, instruments: [InstrumentPart]) {
        self.seconds = seconds
        self.instruments = instruments
    }

    /// The length of the passage, or `nil` when it lasts as long as the part.
    var duration: Duration? {
        seconds.map { .seconds($0) }
    }
}

/// An instrument's part in a passage: how its notes are selected, and how loudly they're played.
struct InstrumentPart: Sendable, Equatable {
    var instrument: InstrumentName
    var notes: NoteSelection
    /// The volume from 0, silent, to 1, full. The velocity of each note is scaled by it, so the
    /// notes keep their varying dynamics, only softer.
    var volume: Double

    init(instrument: InstrumentName, notes: NoteSelection = .standard, volume: Double = 1) {
        self.instrument = instrument
        self.notes = notes
        self.volume = volume
    }
}

extension InstrumentPart: Codable {
    enum CodingKeys: String, CodingKey {
        case instrument, notes, volume
    }

    /// The notes may be left out of the score, meaning they are selected in the standard way, and the
    /// volume may be left out, meaning full volume.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instrument = try container.decode(InstrumentName.self, forKey: .instrument)
        notes = try container.decodeIfPresent(NoteSelection.self, forKey: .notes) ?? .standard
        volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 1
        guard (0...1).contains(volume) else {
            throw DecodingError.dataCorruptedError(forKey: .volume, in: container,
                                                   debugDescription: "The volume of \(instrument) must be between 0 and 1, not \(volume).")
        }
    }
}

// MARK: - The standard score

extension Score {
    /// The score as the performance was first written: the string trio, followed by a second's rest,
    /// introduces the ballad and opens each canto, stanza and line before its first part is recited.
    /// The voices take turns starting with the first.
    static let standard = Score(title: "The Ballad of Connaught Square",
                                voices: VoiceNotation(roles: ["First", "Second"], rule: .alternate(startingWith: 0)),
                                introduction: Interlude(before: .stringTrio(seconds: 13)),
                                canto: Interlude(before: .stringTrio(seconds: 11)),
                                stanza: Interlude(before: .stringTrio(seconds: 7)),
                                line: Interlude(before: .stringTrio(seconds: 5)),
                                part: Interlude(before: [.rest(seconds: 1)]))
}

private extension [Segment] {
    /// The violin, viola and cello play, followed by a second's rest.
    static func stringTrio(seconds: Double) -> [Segment] {
        let passage = Passage(seconds: seconds, instruments: [InstrumentPart(instrument: .violin),
                                                              InstrumentPart(instrument: .viola),
                                                              InstrumentPart(instrument: .cello)])
        return [.music(passage), .rest(seconds: 1)]
    }
}
