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
            Part(speaker: $0, string: "The cat sat on mat number \($0).")
        })
        let secondLine = makeLine(parts: [Part(speaker: 0, string: "The dog barked loudly.")])
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

    func playDuration(of event: Event) -> Duration? {
        guard case .play(_, let duration) = event else { return nil }
        return duration
    }

    func silenceDuration(of event: Event) -> Duration? {
        guard case .silence(let duration) = event else { return nil }
        return duration
    }

    /// A passage of music for one instrument.
    func passage(seconds: Double, instrument: InstrumentName = .viola) -> Segment {
        .music(Passage(seconds: seconds, instruments: [InstrumentPart(instrument: instrument)]))
    }

    /// The ballad is introduced by thirteen seconds of music and a second of silence, which the first part waits for.
    @Test func testFirstCueIntroducesTheBallad() throws {
        var sequence = makeSequence()
        let cue = try nextCue(of: &sequence)
        #expect(cue.before.count == 2)
        #expect(playDuration(of: cue.before[0]) == .seconds(13))
        #expect(silenceDuration(of: cue.before[1]) == .seconds(1))
        #expect(cue.under.isEmpty)
    }

    /// A new line opens with five seconds of music and a second of silence, which the part waits for.
    @Test func testNewLineOpensWithMusic() throws {
        var sequence = makeSequence(partsInFirstLine: 1)
        _ = sequence.next()
        let cue = try nextCue(of: &sequence)
        #expect(cue.before.count == 2)
        #expect(playDuration(of: cue.before[0]) == .seconds(5))
        #expect(silenceDuration(of: cue.before[1]) == .seconds(1))
        #expect(cue.under.isEmpty)
    }

    /// The last part of a line is separated from the part before it by a second of silence, like a middle part.
    @Test func testLastPartOfALineIsPrecededBySilence() throws {
        let lastPart = "The cat sat on mat number 1."
        let cue = try #require(cue(reciting: lastPart, in: try cues(partsInFirstLine: 2)))
        #expect(cue.before.count == 1)
        #expect(silenceDuration(of: cue.before[0]) == .seconds(1))
        #expect(cue.under.isEmpty)
    }

    /// A part in the middle of a line is separated from the part before it by a second of silence.
    @Test func testMiddlePartOfALineIsPrecededBySilence() throws {
        let middlePart = "The cat sat on mat number 1."
        let cue = try #require(cue(reciting: middlePart, in: try cues(partsInFirstLine: 3)))
        #expect(cue.before.count == 1)
        #expect(silenceDuration(of: cue.before[0]) == .seconds(1))
        #expect(cue.under.isEmpty)
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

    /// A score can notate music before the part, which the part waits for, as well as under it.
    @Test func testMusicBeforeThePart() throws {
        var score = Score.standard
        score.line = Interlude(before: [passage(seconds: 2), .rest(seconds: 0.5)], under: [passage(seconds: 3, instrument: .cello)])
        var sequence = makeSequence(partsInFirstLine: 1, score: score)
        _ = sequence.next()
        let cue = try nextCue(of: &sequence)
        #expect(cue.before.count == 2)
        #expect(playDuration(of: cue.before[0]) == .seconds(2))
        #expect(silenceDuration(of: cue.before[1]) == .milliseconds(500))
        #expect(cue.under.count == 1)
        #expect(playDuration(of: cue.under[0]) == .seconds(3))
    }

    /// The passage's instruments are the ones in the score.
    @Test func testPassageIsOrchestratedForItsInstruments() throws {
        var score = Score.standard
        score.introduction = Interlude(under: [.music(Passage(seconds: 2, instruments: [InstrumentPart(instrument: .acousticGrandPiano),
                                                                                         InstrumentPart(instrument: .harpsichord)]))])
        var sequence = makeSequence(score: score)
        let cue = try nextCue(of: &sequence)
        guard case .play(let orchestration, _) = try #require(cue.under.first) else {
            Issue.record("Expected music under the first part")
            return
        }
        #expect(orchestration.assignments.map(\.instrument.name) == [.acousticGrandPiano, .harpsichord])
        #expect(orchestration.assignments.map(\.volume) == [1, 1])
    }

    /// Each instrument plays at the volume the score gives it.
    @Test func testPassageVolumes() throws {
        var score = Score.standard
        score.introduction = Interlude(under: [.music(Passage(instruments: [InstrumentPart(instrument: .viola, volume: 0.3),
                                                                            InstrumentPart(instrument: .cello)]))])
        var sequence = makeSequence(score: score)
        let cue = try nextCue(of: &sequence)
        guard case .accompany(let orchestration) = try #require(cue.under.first) else {
            Issue.record("Expected the viola and cello to accompany the part")
            return
        }
        #expect(orchestration.assignments.map(\.volume) == [0.3, 1])
    }

    /// A passage without instruments is a rest of the same length.
    @Test func testPassageWithoutInstrumentsIsARest() throws {
        var score = Score.standard
        score.introduction = Interlude(before: [.music(Passage(seconds: 2, instruments: []))])
        var sequence = makeSequence(score: score)
        let cue = try nextCue(of: &sequence)
        #expect(silenceDuration(of: try #require(cue.before.first)) == .seconds(2))
    }

    /// A passage without seconds accompanies the part, composed for as long as the part is expected to take.
    @Test func testPassageLastingAsLongAsThePart() throws {
        var score = Score.standard
        score.introduction = Interlude(under: [.music(Passage(instruments: [InstrumentPart(instrument: .viola)])), .rest(seconds: 1)])
        var sequence = makeSequence(score: score)
        let cue = try nextCue(of: &sequence)
        #expect(cue.under.count == 2)
        guard case .accompany(let orchestration) = try #require(cue.under.first) else {
            Issue.record("Expected the viola to accompany the part")
            return
        }
        #expect(orchestration.assignments.map(\.instrument.name) == [.viola])
        #expect(silenceDuration(of: cue.under[1]) == .seconds(1))
    }

    /// A passage without seconds, or without instruments as well, is left out where it can't be measured.
    @Test func testPassageWithoutSecondsIsLeftOut() throws {
        var score = Score.standard
        score.introduction = Interlude(before: [.music(Passage(instruments: [InstrumentPart(instrument: .viola)]))],
                                       under: [.music(Passage(instruments: []))])
        var sequence = makeSequence(score: score)
        let cue = try nextCue(of: &sequence)
        #expect(cue.before.isEmpty)
        #expect(cue.under.isEmpty)
    }

    /// The introduction opens the ballad only, and the other interludes open their divisions.
    @Test func testIntroductionOpensOnlyTheBallad() throws {
        var score = Score.standard
        score.introduction = Interlude(before: [.rest(seconds: 3)])
        score.canto = Interlude(before: [.rest(seconds: 4)])
        score.stanza = Interlude(before: [.rest(seconds: 5)])
        score.line = Interlude(before: [.rest(seconds: 6)])
        score.part = Interlude(before: [.rest(seconds: 7)])
        let cues = try cues(partsInFirstLine: 2, score: score)
        let rests = cues.map { silenceDuration(of: $0.before[0]) }
        // Three parts: the first opens the ballad, the second follows in the same line, and the third opens a line.
        #expect(rests.first == .seconds(3))
        #expect(rests.filter { $0 == .seconds(3) }.count == 1)
        #expect(rests.contains(.seconds(7)))
        #expect(rests.contains(.seconds(6)))
        #expect(rests.contains(.seconds(4)) == false)
    }

    /// Parts can be given to roles by their position in the line.
    @Test func testVoicesByPartIndex() throws {
        var score = Score.standard
        score.voices.rule = .byPartIndex(roles: [0, 1])
        let speakers = Speakers()
        let ballad = makeBallad(partsInFirstLine: 2)
        var sequence = EventsSequence(performance: Performance(score: score, ballad: ballad, speakers: speakers))
        for _ in 1...ballad.parts.count {
            let cue = try nextCue(of: &sequence)
            let line = try #require(ballad.cantos.flatMap(\.stanzas).flatMap(\.lines).first { $0.parts.contains(cue.part) })
            let index = try #require(line.parts.firstIndex(of: cue.part))
            #expect(cue.speaker == speakers.speaker(forRole: index))
        }
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
