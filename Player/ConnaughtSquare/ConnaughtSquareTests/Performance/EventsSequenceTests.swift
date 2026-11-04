//
//  EventsSequenceTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Testing
@testable import ConnaughtSquare

@MainActor
struct EventsSequenceTests {

    /// A line tagged as starting with a determiner. The tag is given rather than found by
    /// `LinguisticTagger`, as the lexical class model isn't available on every run destination.
    func makeLine(parts: [Part]) -> Line {
        Line(parts: parts, tags: [.determiner])
    }

    /// A ballad of one canto, one stanza, two lines and three parts.
    /// Both lines start with a determiner so that they are gathered into a canto.
    func makeBallad(partsInFirstLine: Int = 2) -> Ballad {
        let firstLine = makeLine(parts: (0..<partsInFirstLine).map {
            Part(string: "The cat sat on mat number \($0).")
        })
        let secondLine = makeLine(parts: [Part(string: "The dog barked loudly.")])
        return Ballad(lines: [firstLine, secondLine],
                      tags: LinguisticTagOrder(tags: [.determiner(weight: 1)]))
    }

    func makeSequence(partsInFirstLine: Int = 2, score: Score = .standard) -> EventsSequence {
        let performance = Performance(score: score,
                                      ballad: makeBallad(partsInFirstLine: partsInFirstLine),
                                      speakers: Speakers())
        return EventsSequence(performance: performance)
    }

    /// The next cue. The sequence is mutating, so it can't be advanced inside `#require`.
    func nextCue(of sequence: inout EventsSequence) throws -> Cue {
        let cue = sequence.next()
        return try #require(cue)
    }

    /// One cue for each part of the ballad. A ballad sorts its lines, so the cues are matched
    /// by the part they recite rather than by position.
    func cues(partsInFirstLine: Int, score: Score = .standard) throws -> [Cue] {
        let ballad = makeBallad(partsInFirstLine: partsInFirstLine)
        var sequence = EventsSequence(performance: Performance(score: score, ballad: ballad, speakers: Speakers()))
        var cues: [Cue] = []
        for _ in 0..<ballad.parts.count {
            cues.append(try nextCue(of: &sequence))
        }
        return cues
    }

    func cue(reciting string: String, in cues: [Cue]) -> Cue? {
        cues.first { $0.part.string == string }
    }

    /// A track playing from the start for some seconds.
    func track(_ instruments: [InstrumentName], seconds: Double) -> Track {
        Track(instruments: instruments, stretches: [Stretch(start: .seconds(0), end: .seconds(seconds))])
    }

    /// The ballad is introduced by the string trio playing for thirteen seconds and a second's rest,
    /// and then the first part, opening the first stanza, is recited straight away.
    @Test func testFirstCueIntroducesTheBallad() throws {
        var sequence = makeSequence()
        let cue = try nextCue(of: &sequence)
        #expect(cue.intermissionLength == .seconds(14))
        #expect(cue.intermission.map(\.instrument.name) == [.violin, .viola, .cello])
        #expect(cue.intermission.allSatisfy { $0.stretches == [Stretch(start: .seconds(0), end: .seconds(13))] })
        #expect(cue.recitationStart == .zero)
        #expect(cue.events.isEmpty)
    }

    /// A new line in the same stanza opens with five seconds of music, with no intermission, and its
    /// part is recited a second after the music stops.
    @Test func testNewLineOpensWithMusic() throws {
        var sequence = makeSequence(partsInFirstLine: 1)
        _ = sequence.next()
        let cue = try nextCue(of: &sequence)
        #expect(cue.intermission.isEmpty)
        #expect(cue.intermissionLength == .zero)
        #expect(cue.recitationStart == .seconds(6))
        #expect(cue.events.count == 3)
        #expect(cue.events.allSatisfy { $0.stretches == [Stretch(start: .seconds(0), end: .seconds(5))] })
    }

    /// The last part of a line is recited a second into its cue, like a middle part, with no music.
    @Test func testLastPartOfALineFollowsASilence() throws {
        let lastPart = "The cat sat on mat number 1."
        let cue = try #require(cue(reciting: lastPart, in: try cues(partsInFirstLine: 2)))
        #expect(cue.recitationStart == .seconds(1))
        #expect(cue.events.isEmpty)
        #expect(cue.intermission.isEmpty)
    }

    /// A part in the middle of a line is recited a second into its cue, with no music.
    @Test func testMiddlePartOfALineFollowsASilence() throws {
        let middlePart = "The cat sat on mat number 1."
        let cue = try #require(cue(reciting: middlePart, in: try cues(partsInFirstLine: 3)))
        #expect(cue.recitationStart == .seconds(1))
        #expect(cue.events.isEmpty)
        #expect(cue.intermission.isEmpty)
    }

    /// Each part of the ballad is recited once, in order.
    @Test func testEachPartIsRecitedInOrder() throws {
        let ballad = makeBallad()
        var sequence = EventsSequence(performance: Performance(score: .standard, ballad: ballad, speakers: Speakers()))
        var recited: [String] = []
        for _ in 1...ballad.parts.count {
            recited.append(try nextCue(of: &sequence).part.string)
        }
        #expect(recited == ballad.parts.map { $0.string })
    }

    /// In the standard score the speakers take turns, starting with the first speaker.
    @Test func testSpeakersAlternate() throws {
        let speakers = Speakers()
        let first = speakers.speaker(forRole: 0)
        let second = speakers.speaker(forRole: 1)
        let performance = Performance(score: .standard, ballad: makeBallad(), speakers: speakers)
        var sequence = EventsSequence(performance: performance)
        var names: [String] = []
        for _ in 1...3 {
            names.append(try nextCue(of: &sequence).speaker.name)
        }
        #expect(names == [first.name, second.name, first.name])
    }

    /// Each sequence starts the turns afresh, so a performance stopped after an odd number of
    /// parts still starts the next one with the first speaker.
    @Test func testEachSequenceStartsTheTurnsAfresh() throws {
        let speakers = Speakers()
        let performance = Performance(score: .standard, ballad: makeBallad(), speakers: speakers)
        var first = EventsSequence(performance: performance)
        _ = try nextCue(of: &first)
        var second = EventsSequence(performance: performance)
        #expect(try nextCue(of: &second).speaker == speakers.speaker(forRole: 0))
    }

    /// Each instrument of each track has an event of its own, playing the track's stretches.
    @Test func testEventForEachInstrument() throws {
        var score = Score.standard
        let stretches = [Stretch(start: .seconds(0), end: .seconds(5)),
                         Stretch(start: .seconds(5), end: .afterRecitation(seconds: 1), volume: 0.6)]
        score.firstLine = Interlude(recitationStart: 5.5,
                                       tracks: [track([.acousticGrandPiano, .harpsichord], seconds: 2),
                                                Track(instruments: [.viola], stretches: stretches)])
        var sequence = makeSequence(score: score)
        let cue = try nextCue(of: &sequence)
        #expect(cue.recitationStart == .milliseconds(5500))
        #expect(cue.events.map(\.instrument.name) == [.acousticGrandPiano, .harpsichord, .viola])
        #expect(cue.events.last?.stretches == stretches)
    }

    /// An instrument playing until the part has been recited has a melody composed for as long as
    /// the part is expected to take, so it doesn't need to repeat.
    @Test func testMelodyLastsAsLongAsThePart() throws {
        var score = Score.standard
        score.firstLine = Interlude(recitationStart: 2,
                                       tracks: [Track(instruments: [.viola], stretches: [Stretch(start: .seconds(1), end: .endOfRecitation)])])
        let ballad = makeBallad()
        var sequence = EventsSequence(performance: Performance(score: score, ballad: ballad, speakers: Speakers()))
        let cue = try nextCue(of: &sequence)
        let event = try #require(cue.events.first)
        let length = event.notes.elements.reduce(Duration.zero) { $0 + $1.duration.duration }
        #expect(length >= .seconds(1) + cue.part.duration)
    }

    /// An instrument that continues carries on the melody it stopped at in the part before, and one
    /// that doesn't, or that the part before didn't play, starts a new one.
    @Test func testInstrumentContinuesItsMelody() throws {
        var score = Score.standard
        let stretches = [Stretch(start: .seconds(0), end: .endOfRecitation)]
        score.part = Interlude(tracks: [Track(instruments: [.viola, .cello], stretches: stretches, continues: true),
                                        Track(instruments: [.violin], stretches: stretches)])
        var sequence = makeSequence(partsInFirstLine: 2, score: score)
        _ = sequence.next()
        var melody = Cycle(elements: [Note(value: .a2, duration: .quaver), Note(value: .c3, duration: .quaver)])
        _ = melody.next()
        let next = sequence.next(continuing: [.viola: melody, .violin: melody])
        let cue = try #require(next)
        let notes = Dictionary(uniqueKeysWithValues: cue.events.map { ($0.instrument.name, $0.notes) })
        #expect(notes[.viola]?.elements == melody.elements)
        #expect(notes[.viola]?.currentIndex == melody.currentIndex)
        // The cello didn't play in the part before, and the violin doesn't continue.
        #expect(notes[.cello]?.elements != melody.elements)
        #expect(notes[.violin]?.elements != melody.elements)
    }

    /// An intermission starts every melody afresh, even for an instrument that continues.
    @Test func testIntermissionStartsMelodiesAfresh() throws {
        var score = Score.standard
        score.firstLine = Interlude(tracks: [Track(instruments: [.viola], stretches: [Stretch(start: .seconds(0), end: .endOfRecitation)], continues: true)])
        var sequence = makeSequence(score: score)
        let melody = Cycle(elements: [Note(value: .a2, duration: .quaver)])
        let next = sequence.next(continuing: [.viola: melody])
        let cue = try #require(next)
        #expect(cue.intermission.isEmpty == false)
        #expect(cue.events.first?.notes.elements != melody.elements)
    }

    /// The introduction plays before the ballad only, and the stanza's first line, each later line and
    /// each part are opened by their own interludes.
    @Test func testIntroductionPlaysOnlyBeforeTheBallad() throws {
        var score = Score.standard
        score.introduction = Intermission(seconds: 3)
        score.canto = Intermission(seconds: 4)
        score.stanza = Intermission(seconds: 5)
        score.firstLine = Interlude(recitationStart: 8)
        score.line = Interlude(recitationStart: 6)
        score.part = Interlude(recitationStart: 7)
        let cues = try cues(partsInFirstLine: 2, score: score)
        // Three parts: the first opens the ballad, the second follows in the same line, and the third opens a line.
        #expect(cues.map(\.intermissionLength).sorted() == [.zero, .zero, .seconds(3)])
        #expect(cues.first?.intermissionLength == .seconds(3))
        #expect(cues.first?.recitationStart == .seconds(8))
        #expect(cues.map(\.recitationStart).sorted() == [.seconds(6), .seconds(7), .seconds(8)])
    }

    /// Once the last part has been recited the sequence finishes rather than starting the ballad over.
    @Test func testSequenceFinishesAfterTheLastPart() throws {
        let ballad = makeBallad()
        var sequence = EventsSequence(performance: Performance(score: .standard, ballad: ballad, speakers: Speakers()))
        for _ in 1...ballad.parts.count {
            _ = try nextCue(of: &sequence)
        }
        if let cue = sequence.next() {
            Issue.record("Expected no further cues but got \(cue).")
        }
    }

    /// A ballad with no parts has no cues.
    @Test func testEmptyBalladHasNoCues() {
        var sequence = EventsSequence(performance: Performance(score: .standard, ballad: Ballad(lines: []), speakers: Speakers()))
        #expect(sequence.next() == nil)
    }
}
