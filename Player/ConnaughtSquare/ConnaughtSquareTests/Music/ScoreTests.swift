//
//  ScoreTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 01/11/2026.
//

import Foundation
import Testing
@testable import ConnaughtSquare

struct ScoreTests {

    func decode<Value: Decodable>(_ type: Value.Type, from json: String) throws -> Value {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func testStandardScoreRoundTrips() throws {
        let data = try JSONEncoder().encode(Score.standard)
        #expect(try JSONDecoder().decode(Score.self, from: data) == Score.standard)
    }

    /// The score in the app's assets is the standard score with the viola playing quietly under every
    /// part, for as long as the part takes to recite.
    @Test func testBundledScore() throws {
        var expected = Score.standard
        let viola = Segment.music(Passage(instruments: [InstrumentPart(instrument: .viola, volume: 0.6)]))
        let interludes: [WritableKeyPath<Score, Interlude>] = [\.introduction, \.canto, \.stanza, \.line, \.part]
        for interlude in interludes {
            expected[keyPath: interlude].under = [viola]
        }
        #expect(try Score.asset() == expected)
    }

    /// An instrument's volume may be left out, meaning full volume.
    @Test func testInstrumentVolume() throws {
        #expect(try decode(InstrumentPart.self, from: #"{ "instrument": "Viola", "volume": 0.4 }"#).volume == 0.4)
        #expect(try decode(InstrumentPart.self, from: #"{ "instrument": "Viola" }"#).volume == 1)
    }

    /// A volume outside 0 to 1 is a mistake in the score.
    @Test(arguments: ["-0.1", "1.5"])
    func testInstrumentVolumeOutOfRange(volume: String) {
        #expect(throws: DecodingError.self) {
            try decode(InstrumentPart.self, from: #"{ "instrument": "Viola", "volume": \#(volume) }"#)
        }
    }

    /// A passage written without seconds lasts as long as the part, and is written without them.
    @Test func testPassageWithoutSeconds() throws {
        let passage = try decode(Passage.self, from: #"{ "instruments": [{ "instrument": "Viola" }] }"#)
        #expect(passage == Passage(instruments: [InstrumentPart(instrument: .viola)]))
        #expect(passage.duration == nil)
        let encoded = String(decoding: try JSONEncoder().encode(passage), as: UTF8.self)
        #expect(!encoded.contains("seconds"))
    }

    @Test func testMissingScore() {
        #expect(throws: AssetError.self) {
            try Score.asset(named: "NoSuchScore")
        }
    }

    /// Segments are written as music or a rest.
    @Test func testDecodeSegments() throws {
        let json = """
        [
            { "music": { "seconds": 7, "instruments": [
                { "instrument": "Violin", "notes": { "tunes": ["theSashMyFatherWore"], "vectorWidth": 2, "operations": ["intersection"] } },
                { "instrument": "Cello" } ] } },
            { "rest": 1.5 }
        ]
        """
        let segments = try decode([Segment].self, from: json)
        let violin = InstrumentPart(instrument: .violin,
                                    notes: NoteSelection(tunes: [.theSashMyFatherWore], vectorWidth: 2, operations: [.intersection]))
        let cello = InstrumentPart(instrument: .cello)
        #expect(segments == [.music(Passage(seconds: 7, instruments: [violin, cello])), .rest(seconds: 1.5)])
    }

    @Test func testEncodeSegments() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode([Segment.rest(seconds: 1)])
        #expect(String(decoding: data, as: UTF8.self) == #"[{"rest":1}]"#)
    }

    @Test func testSegmentMustBeMusicOrRest() {
        #expect(throws: DecodingError.self) {
            try decode(Segment.self, from: #"{ "silence": 1 }"#)
        }
    }

    /// Anything left out of a note selection is selected in the standard way.
    @Test func testNoteSelectionDefaults() throws {
        let selection = try decode(NoteSelection.self, from: #"{ "vectorWidth": 2 }"#)
        #expect(selection == NoteSelection(vectorWidth: 2))
        #expect(try decode(NoteSelection.self, from: "{}") == .standard)
    }

    /// Either list may be left out of an interlude.
    @Test func testInterludeDefaults() throws {
        #expect(try decode(Interlude.self, from: "{}") == Interlude())
        #expect(try decode(Interlude.self, from: #"{ "before": [{ "rest": 1 }] }"#) == Interlude(before: [.rest(seconds: 1)]))
    }

    @Test func testVoiceRules() throws {
        #expect(try decode(VoiceRule.self, from: #"{ "alternate": { "startingWith": 1 } }"#) == .alternate(startingWith: 1))
        #expect(try decode(VoiceRule.self, from: #"{ "byPartIndex": { "roles": [0, 1] } }"#) == .byPartIndex(roles: [0, 1]))
        #expect(try decode(VoiceRule.self, from: #"{ "asWritten": {} }"#) == .asWritten)
    }

    /// Instruments are written by name.
    @Test func testInstrumentNames() throws {
        #expect(try decode([InstrumentName].self, from: #"["Violin", "Acoustic Grand Piano"]"#) == [.violin, .acousticGrandPiano])
        #expect(String(decoding: try JSONEncoder().encode([InstrumentName.cello]), as: UTF8.self) == #"["Cello"]"#)
        #expect(throws: DecodingError.self) {
            try decode(InstrumentName.self, from: #""Kazoo""#)
        }
    }

    /// Every instrument has its own name, so each can be written in the score.
    @Test func testInstrumentNamesAreDistinct() {
        let names = InstrumentName.allCases.map(\.description)
        #expect(Set(names).count == names.count)
    }

    @Test func testNoteSelections() {
        #expect(Score.standard.noteSelections == [.standard])
        var score = Score.standard
        let intersection = NoteSelection(operations: [.intersection])
        score.part = Interlude(under: [.music(Passage(seconds: 1, instruments: [InstrumentPart(instrument: .flute, notes: intersection)]))])
        #expect(score.noteSelections == [.standard, intersection])
    }
}
