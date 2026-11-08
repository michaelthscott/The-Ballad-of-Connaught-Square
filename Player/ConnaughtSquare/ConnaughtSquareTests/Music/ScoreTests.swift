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

    /// The score in the app's assets reads, with music in each intermission, and a recitation
    /// opening each line and later part. Its notes are left to the score to change freely.
    @Test func testBundledScore() throws {
        let score = try Score.asset()
        #expect(score.title == "The Ballad of Connaught Square")
        for intermission in score.intermissions {
            #expect(!intermission.tracks.isEmpty)
            #expect(intermission.seconds > 0)
        }
        #expect(score.line.recitationStart > 0)
    }

    /// The score as written in the source folder reads, so a mistake in it is caught even when the
    /// app's assets were built from an earlier copy.
    @Test func testScoreSourceReads() throws {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../ConnaughtSquare/Assets.xcassets/Score.dataset/Score.md")
        let markdown = try String(contentsOf: url, encoding: .utf8)
        #expect(throws: Never.self) { try Score(markdown: markdown) }
    }

    /// An intermission lasts until its last stretch ends, or longer if it's given a length.
    @Test func testIntermissionLength() {
        let tracks = [Track(instruments: [.viola], stretches: [Stretch(start: .seconds(0), end: .seconds(5))])]
        #expect(Intermission(tracks: tracks).seconds == 5)
        #expect(Intermission(tracks: tracks, seconds: 7).seconds == 7)
        #expect(Intermission(tracks: tracks, seconds: 3).seconds == 5)
        #expect(Intermission().seconds == 0)
    }

    @Test func testMissingScore() {
        #expect(throws: AssetError.self) {
            try Score.asset(named: "NoSuchScore")
        }
    }

    /// A moment from the end of the recitation is expected once the recitation is expected to finish.
    @Test func testExpectedMoment() {
        #expect(Moment.seconds(2).expected(recitationEnd: .seconds(10)) == .seconds(2))
        #expect(Moment.afterRecitation(seconds: 1).expected(recitationEnd: .seconds(10)) == .seconds(11))
    }

    /// Only a time from the start is certainly before a time from the end, whatever the recitation's length.
    @Test func testMomentOrder() {
        #expect(Moment.seconds(1).isBefore(.seconds(2)))
        #expect(!Moment.seconds(2).isBefore(.seconds(2)))
        #expect(Moment.seconds(100).isBefore(.endOfRecitation))
        #expect(Moment.endOfRecitation.isBefore(.afterRecitation(seconds: 1)))
        #expect(!Moment.endOfRecitation.isBefore(.seconds(100)))
    }

    /// Stretches are described as they're written in a score.
    @Test func testStretchDescription() {
        #expect(Stretch(start: .seconds(0), end: .seconds(5.5)).description == "0s–5.5s")
        #expect(Stretch(start: .seconds(5), end: .afterRecitation(seconds: 1), volume: 0.6).description == "5s–end+1s at 60%")
        #expect(Stretch(start: .seconds(5), end: .endOfRecitation).description == "5s–end")
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
        score.part = Interlude(tracks: [Track(instruments: [.flute], notes: intersection, stretches: [Stretch(start: .seconds(0), end: .seconds(1))])])
        #expect(score.noteSelections == [.standard, intersection])
    }

    @Test func testInstruments() {
        #expect(Score.standard.instruments == [.violin, .viola, .cello])
        var score = Score.standard
        score.part = Interlude(tracks: [Track(instruments: [.flute], stretches: [Stretch(start: .seconds(0), end: .seconds(1))])])
        #expect(score.instruments == [.violin, .viola, .cello, .flute])
    }

    // MARK: - Markdown

    /// A score in Markdown, with the later parts' cues given, each intermission a second's rest, and
    /// each other line simply recited.
    func markdown(laterPart cues: [String] = ["- Recite: 0s"]) -> String {
        """
        # Test

        ## Ballad

        ### Introduction

        - Rest: 0s–1s

        ## Canto

        ### Intermission

        - Rest: 0s–1s

        ## Stanza

        ### First line

        - Recite: 0s

        ### Later line

        - Recite: 0s

        ### Intermission

        - Rest: 0s–1s

        ## Line

        ### Later parts

        \(cues.joined(separator: "\n"))
        """
    }

    @Test func testReadMarkdown() throws {
        let score = try Score(markdown: markdown())
        #expect(score.title == "Test")
        for intermission in score.intermissions {
            #expect(intermission == Intermission(seconds: 1))
        }
        for interlude in score.interludes {
            #expect(interlude == Interlude())
        }
    }

    /// A description, written as a quote, is skipped wherever it goes, so the score reads the same.
    @Test func testReadMarkdownDescriptions() throws {
        let described = markdown()
            .replacingOccurrences(of: "# Test\n", with: "> A score for testing.\n# Test\n>\n")
            .replacingOccurrences(of: "## Canto\n", with: "## Canto\n\n> After each canto.\n")
            .replacingOccurrences(of: "### Introduction\n", with: "### Introduction\n\n>Before the ballad.\n")
            .replacingOccurrences(of: "- Recite: 0s\n", with: "- Recite: 0s\n  > Straight away.\n")
        #expect(try Score(markdown: described) == Score(markdown: markdown()))
    }

    /// Each instrument line gives its instruments' stretches, and Recite says when the part starts,
    /// wherever it's written in the list.
    @Test func testReadMarkdownCues() throws {
        let score = try Score(markdown: markdown(laterPart: ["- Violin, Cello: 0s–5s",
                                                             "- Recite: 5.5s",
                                                             "- Viola: 0s-5s, 5s–end+1s at 60%",
                                                             "- Flute: 1s–2s at 0%, 3s–end, end+0.5s–end+2s"]))
        let expected = Interlude(recitationStart: 5.5, tracks: [
            Track(instruments: [.violin, .cello], stretches: [Stretch(start: .seconds(0), end: .seconds(5))]),
            Track(instruments: [.viola], stretches: [Stretch(start: .seconds(0), end: .seconds(5)),
                                                     Stretch(start: .seconds(5), end: .afterRecitation(seconds: 1), volume: 0.6)]),
            Track(instruments: [.flute], stretches: [Stretch(start: .seconds(1), end: .seconds(2), volume: 0),
                                                     Stretch(start: .seconds(3), end: .endOfRecitation),
                                                     Stretch(start: .afterRecitation(seconds: 0.5), end: .afterRecitation(seconds: 2))]),
        ])
        #expect(score.part == expected)
    }

    /// Mistakes in a division's cues, each with the line it's on.
    static let mistakes: [([String], Int)] = [
        (["- Kazoo: 0s–1s", "- Recite: 0s"], 33),                  // No such instrument.
        (["- Viola: 0s–1s at 120%", "- Recite: 0s"], 33),          // Too loud.
        (["- Viola: 0s–1", "- Recite: 0s"], 33),                   // A time without seconds.
        (["- Viola: 0s", "- Recite: 0s"], 33),                     // A time rather than a stretch.
        (["- Viola: 2s–1s", "- Recite: 0s"], 33),                  // A stretch that ends before it starts.
        (["- Viola: 1s–1s", "- Recite: 0s"], 33),                  // A stretch that ends as it starts.
        (["- Viola: 0s–2s, 1s–3s", "- Recite: 0s"], 33),           // Overlapping stretches.
        (["- Viola: end–end+1s, 1s–2s", "- Recite: 0s"], 33),      // A time from the start after the end.
        (["- Viola: end–2s", "- Recite: 0s"], 33),                 // A stretch from the end to a time from the start.
        (["- Viola: 0s–1s", "- Viola, Cello: 2s–3s", "- Recite: 0s"], 34), // An instrument named twice.
        (["- Viola 0s–1s", "- Recite: 0s"], 33),                   // No colon.
        (["- Kazoo continues: 0s–1s", "- Recite: 0s"], 33),        // No such instrument to continue.
        (["- Recite: end"], 33),                                   // Recited from the end of the recitation.
        (["- Recite: 0s", "- Recite: 1s"], 34),                    // Recited twice.
        (["- Rest: 0s–1s", "- Recite: 0s"], 33),                   // A rest outside an intermission.
        (["Recite: 0s"], 33),                                      // Not a list item.
        (["- Viola: 0s–1s", "### Title"], 34),                     // A division without Recite before the next.
        (["- Recite: 0s", "### Later parts"], 34),                 // A division twice.
        (["- Recite: 0s", "### Title"], 34),                       // A division its group doesn't have.
        (["- Recite: 0s", "## Coda"], 34),                         // No such group.
        (["- Recite: 0s", "## Stanza"], 34),                       // A group twice.
    ]

    @Test(arguments: mistakes)
    func testMarkdownMistakes(cues: [String], line: Int) {
        let error = #expect(throws: ScoreError.self) { try Score(markdown: markdown(laterPart: cues)) }
        #expect(error?.line == line, "\(String(describing: error))")
    }

    /// An intermission's instruments and rests, which together give its length.
    @Test func testReadMarkdownIntermission() throws {
        let markdown = markdown().replacingOccurrences(of: "## Canto\n\n### Intermission\n\n- Rest: 0s–1s",
                                                       with: "## Canto\n\n### Intermission\n\n- Violin: 2s–11s\n- Cello: 0s–13s at 50%\n- Rest: 13s–15s")
        let score = try Score(markdown: markdown)
        let expected = Intermission(tracks: [Track(instruments: [.violin], stretches: [Stretch(start: .seconds(2), end: .seconds(11))]),
                                             Track(instruments: [.cello], stretches: [Stretch(start: .seconds(0), end: .seconds(13), volume: 0.5)])],
                                    seconds: 15)
        #expect(score.canto == expected)
    }

    /// A canto title rests until its last rest ends, and a score without one doesn't rest.
    @Test func testReadMarkdownCantoTitle() throws {
        #expect(try Score(markdown: markdown()).cantoTitleRest == 0)
        let markdown = markdown().replacingOccurrences(of: "## Canto\n\n",
                                                       with: "## Canto\n\n### Title\n\n- Rest: 0s–2s, 2s–2.5s\n\n")
        #expect(try Score(markdown: markdown).cantoTitleRest == 2.5)
    }

    /// A ballad title rests until its last rest ends, and a score without one doesn't rest.
    @Test func testReadMarkdownBalladTitle() throws {
        #expect(try Score(markdown: markdown()).balladTitleRest == 0)
        let markdown = markdown().replacingOccurrences(of: "## Ballad\n\n",
                                                       with: "## Ballad\n\n### Title\n\n- Rest: 0s–2s\n\n")
        #expect(try Score(markdown: markdown).balladTitleRest == 2)
    }

    /// Instruments can't play in a ballad title, which only rests.
    @Test func testMarkdownBalladTitleMistake() {
        let markdown = markdown().replacingOccurrences(of: "## Ballad\n\n",
                                                       with: "## Ballad\n\n### Title\n\n- Viola: 0s–1s\n\n")
        let error = #expect(throws: ScoreError.self) { try Score(markdown: markdown) }
        #expect(error?.line == 7, "\(String(describing: error))")
    }

    /// Mistakes in a canto title, which only rests, each on line 13.
    @Test(arguments: ["- Viola: 0s–1s",     // An instrument.
                      "- Recite: 0s",       // A recitation.
                      "- Rest: 0s–end"])    // A rest until the end of a recitation.
    func testMarkdownCantoTitleMistakes(cue: String) {
        let markdown = markdown().replacingOccurrences(of: "## Canto\n\n",
                                                       with: "## Canto\n\n### Title\n\n\(cue)\n\n")
        let error = #expect(throws: ScoreError.self) { try Score(markdown: markdown) }
        #expect(error?.line == 13, "\(String(describing: error))")
    }

    /// An instrument written with `continues` carries on its melody from the part before.
    @Test func testReadMarkdownContinues() throws {
        let score = try Score(markdown: markdown(laterPart: ["- Viola continues: 0s–end at 90%", "- Recite: 0.25s"]))
        let expected = Interlude(recitationStart: 0.25,
                                 tracks: [Track(instruments: [.viola],
                                                stretches: [Stretch(start: .seconds(0), end: .endOfRecitation, volume: 0.9)],
                                                continues: true)])
        #expect(score.part == expected)
    }

    /// Mistakes in an intermission, which has nothing recited in it, each on line 13.
    @Test(arguments: ["- Recite: 0s",              // A recitation.
                      "- Viola: 0s–end",           // A time from the end of a recitation.
                      "- Rest: 0s–end+1s",         // A rest until after a recitation.
                      "- Rest: 0s–1s at 50%",      // A rest with a volume.
                      "- Viola continues: 0s–1s"]) // A melody carried on into an intermission.
    func testMarkdownIntermissionMistakes(cue: String) {
        let markdown = markdown().replacingOccurrences(of: "## Canto\n\n### Intermission\n\n- Rest: 0s–1s",
                                                       with: "## Canto\n\n### Intermission\n\n\(cue)")
        let error = #expect(throws: ScoreError.self) { try Score(markdown: markdown) }
        #expect(error?.line == 13, "\(String(describing: error))")
    }

    /// Mistakes in the score as a whole.
    @Test func testMarkdownScoreMistakes() {
        let mistakes = [
            markdown(laterPart: ["- Viola: 0s–1s"]),                                            // A division without Recite.
            markdown().replacingOccurrences(of: "### Intermission\n\n- Rest: 0s–1s\n\n## Line", with: "## Line"), // A division left out.
            markdown().replacingOccurrences(of: "### Introduction", with: "### Voices"),         // No such division.
            markdown().replacingOccurrences(of: "## Ballad\n\n", with: ""),                     // A division under no group.
            markdown().replacingOccurrences(of: "### Introduction\n\n", with: ""),              // A list under a group, not a division.
            markdown().replacingOccurrences(of: "# Test\n\n", with: ""),                        // No title.
        ]
        for mistake in mistakes {
            #expect(throws: ScoreError.self) { try Score(markdown: mistake) }
        }
    }
}
