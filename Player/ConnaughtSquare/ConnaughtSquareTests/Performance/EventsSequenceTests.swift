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

    /// A ballad of one canto, one stanza, two lines and three parts.
    func makeBallad(partsInFirstLine: Int = 2) -> Ballad {
        Ballad.test(partsInFirstLine: partsInFirstLine)
    }

    func makeSequence(partsInFirstLine: Int = 2, score: Score = .standard) -> EventsSequence {
        let performance = Performance(score: score,
                                      ballad: makeBallad(partsInFirstLine: partsInFirstLine),
                                      speakers: Speakers.cached())
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
        var sequence = EventsSequence(performance: Performance(score: score, ballad: ballad, speakers: Speakers.cached()))
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

    /// Only the cue for a canto's first part says which canto it begins, so that its title can be
    /// shown before the stanza is recited.
    @Test func testOnlyTheFirstCueOfACantoBeginsIt() throws {
        let cues = try cues(partsInFirstLine: 2)
        #expect(cues.map(\.cantoIndex) == [0, nil, nil])
    }

    /// Only the cue for a canto's first part rests after the canto's title, for as long as the score says.
    @Test func testCantoTitleRest() throws {
        var score = Score.standard
        score.cantoTitleRest = 2
        let cues = try cues(partsInFirstLine: 2, score: score)
        #expect(cues.map(\.cantoTitleRest) == [.seconds(2), .zero, .zero])
    }

    /// Only the cue for the ballad's first part shows its title and rests after it, before the
    /// introduction, for as long as the score says.
    @Test func testBalladTitleRest() throws {
        var score = Score.standard
        score.balladTitleRest = 2
        let cues = try cues(partsInFirstLine: 2, score: score)
        #expect(cues.map(\.beginsBallad) == [true, false, false])
        #expect(cues.map(\.balladTitleRest) == [.seconds(2), .zero, .zero])
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
        var sequence = EventsSequence(performance: Performance(score: .standard, ballad: ballad, speakers: Speakers.cached()))
        var recited: [String] = []
        for _ in 1...ballad.parts.count {
            recited.append(try nextCue(of: &sequence).part.string)
        }
        #expect(recited == ballad.parts.map { $0.string })
    }

    /// Each cue declaims its own part, ending its line only for the line's last part.
    @Test func testEachCueDeclaimsItsPart() throws {
        let ballad = makeBallad(partsInFirstLine: 3)
        var sequence = EventsSequence(performance: Performance(score: .standard, ballad: ballad, speakers: Speakers.cached()))
        let lines = ballad.cantos.flatMap(\.stanzas).flatMap(\.lines)
        for line in lines {
            for part in line.parts {
                let cue = try nextCue(of: &sequence)
                #expect(cue.declamation.words.map(\.text) == part.string.split(whereSeparator: \.isWhitespace).map(String.init))
                #expect(cue.declamation.position == (line.parts.last === part ? .lineEnd : .caesura))
            }
        }
    }

    /// The declamation's pitch centres on the note the cue's music plays most often, and a part
    /// without music of its own has no baseline.
    @Test func testDeclamationCentresOnTheCuesMusic() throws {
        for cue in try cues(partsInFirstLine: 3) {
            #expect(cue.declamation.baseline == Declamation.baseline(for: cue.events))
            if cue.events.isEmpty {
                #expect(cue.declamation.baseline == nil)
            }
        }
    }

    /// Each cue is played as loud as its speaker's role, as the volume is when the cue is made.
    @Test func testEachCueIsAsLoudAsItsRole() throws {
        let speakers = Speakers.cached()
        speakers.volumes[speakers.roles[1]] = 0.3
        var sequence = EventsSequence(performance: Performance(score: .standard, ballad: makeBallad(), speakers: speakers))
        #expect(try nextCue(of: &sequence).volume == speakers.volume(forRole: 0))
        #expect(try nextCue(of: &sequence).volume == 0.3)
    }

    /// The parts are declaimed in the performance's style, as it is when each cue is made.
    @Test func testDeclaimsInThePerformancesStyle() throws {
        let performance = Performance(score: .standard, ballad: makeBallad(), speakers: Speakers.cached())
        var sequence = EventsSequence(performance: performance)
        #expect(try nextCue(of: &sequence).declamation.style == .standard)
        performance.style.baseRate = 0.5
        #expect(try nextCue(of: &sequence).declamation.style.baseRate == 0.5)
    }

    /// In the standard score the speakers take turns, starting with the first speaker.
    @Test func testSpeakersAlternate() throws {
        let speakers = Speakers.cached()
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

    /// The speakers stand where their roles stand, so in the standard score they alternate from
    /// left to right.
    @Test func testSpeakersStandOnAlternateSides() throws {
        let speakers = Speakers.cached()
        let performance = Performance(score: .standard, ballad: makeBallad(), speakers: speakers)
        var sequence = EventsSequence(performance: performance)
        var pans: [Float] = []
        for _ in 1...3 {
            pans.append(try nextCue(of: &sequence).pan)
        }
        #expect(pans == [speakers.pan(forRole: 0), speakers.pan(forRole: 1), speakers.pan(forRole: 0)])
        #expect(pans[0] < pans[1])
    }

    /// Each sequence starts the turns afresh, so a performance stopped after an odd number of
    /// parts still starts the next one with the first speaker.
    @Test func testEachSequenceStartsTheTurnsAfresh() throws {
        let speakers = Speakers.cached()
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
        var sequence = EventsSequence(performance: Performance(score: score, ballad: ballad, speakers: Speakers.cached()))
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
        var sequence = EventsSequence(performance: Performance(score: .standard, ballad: ballad, speakers: Speakers.cached()))
        for _ in 1...ballad.parts.count {
            _ = try nextCue(of: &sequence)
        }
        if let cue = sequence.next() {
            Issue.record("Expected no further cues but got \(cue).")
        }
    }

    /// A ballad with no parts has no cues.
    @Test func testEmptyBalladHasNoCues() {
        var sequence = EventsSequence(performance: Performance(score: .standard, ballad: Ballad(lines: []), speakers: Speakers.cached()))
        #expect(sequence.next() == nil)
    }

    /// Every sequence of a performance with a seeded generator composes the same music, so a test
    /// can find out what the performance will play.
    @Test func testSeededPerformanceComposesTheSameMusic() throws {
        let performance = Performance(score: .standard, ballad: makeBallad(), speakers: Speakers.cached(),
                                      randomNumberGenerator: SeededRandomNumberGenerator(seed: 7))
        var first = EventsSequence(performance: performance)
        var second = EventsSequence(performance: performance)
        while let cue = first.next() {
            let repeated = try nextCue(of: &second)
            #expect(cue.intermission.map(\.notes.elements) == repeated.intermission.map(\.notes.elements))
            #expect(cue.events.map(\.notes.elements) == repeated.events.map(\.notes.elements))
        }
    }

}
