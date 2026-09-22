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
    /// Both lines start with a determiner so that they are gathered into a canto.
    func makeBallad(partsInFirstLine: Int = 2) -> Ballad {
        let firstLine = Line(parts: (0..<partsInFirstLine).map {
            Part(speaker: $0, string: "The cat sat on mat number \($0).")
        })
        let secondLine = Line(parts: [Part(speaker: 0, string: "The dog barked loudly.")])
        return Ballad(lines: [firstLine, secondLine],
                      tags: LinguisticTagOrder(tags: [.determiner(weight: 1)]))
    }

    func makeSequence(partsInFirstLine: Int = 2) -> EventsSequence {
        let performance = Performance(ballad: makeBallad(partsInFirstLine: partsInFirstLine),
                                      speakers: Speakers())
        return EventsSequence(performance: performance)
    }

    /// The next batch of events. The sequence is mutating, so it can't be advanced inside `#require`.
    func nextBatch(of sequence: inout EventsSequence) throws -> [Event] {
        let batch = sequence.next()
        return try #require(batch)
    }

    /// One batch for each part of the ballad. A ballad sorts its lines, so the batches are matched
    /// by the part they recite rather than by position.
    func batches(partsInFirstLine: Int) throws -> [[Event]] {
        let ballad = makeBallad(partsInFirstLine: partsInFirstLine)
        var sequence = EventsSequence(performance: Performance(ballad: ballad, speakers: Speakers()))
        var batches: [[Event]] = []
        for _ in 0..<ballad.parts.count {
            batches.append(try nextBatch(of: &sequence))
        }
        return batches
    }

    func batch(reciting string: String, in batches: [[Event]]) -> [Event]? {
        batches.first { batch in
            batch.contains { spokenPart(of: $0)?.string == string }
        }
    }

    func playDuration(of event: Event) -> Duration? {
        guard case .play(_, let duration) = event else { return nil }
        return duration
    }

    func silenceDuration(of event: Event) -> Duration? {
        guard case .silence(let duration) = event else { return nil }
        return duration
    }

    func spokenPart(of event: Event) -> Part? {
        guard case .speak(let part, _) = event else { return nil }
        return part
    }

    /// The ballad opens with thirteen seconds of music and a second of silence.
    @Test func testFirstBatchOpensTheBallad() throws {
        var sequence = makeSequence()
        let batch = try nextBatch(of: &sequence)
        #expect(batch.count == 3)
        #expect(playDuration(of: batch[0]) == .seconds(13))
        #expect(silenceDuration(of: batch[1]) == .seconds(1))
        #expect(spokenPart(of: batch[2]) != nil)
    }

    /// A new line opens with five seconds of music and a second of silence.
    @Test func testNewLineOpensWithMusic() throws {
        var sequence = makeSequence(partsInFirstLine: 1)
        _ = sequence.next()
        let batch = try nextBatch(of: &sequence)
        #expect(batch.count == 3)
        #expect(playDuration(of: batch[0]) == .seconds(5))
        #expect(silenceDuration(of: batch[1]) == .seconds(1))
    }

    /// The last part of a line follows on without any accompaniment.
    @Test func testLastPartOfALineHasNoAccompaniment() throws {
        let lastPart = "The cat sat on mat number 1."
        let batch = try #require(batch(reciting: lastPart, in: try batches(partsInFirstLine: 2)))
        #expect(batch.count == 1)
        #expect(spokenPart(of: batch[0])?.string == lastPart)
    }

    /// A part in the middle of a line is separated from the part before it by a second of silence.
    @Test func testMiddlePartOfALineIsPrecededBySilence() throws {
        let middlePart = "The cat sat on mat number 1."
        let batch = try #require(batch(reciting: middlePart, in: try batches(partsInFirstLine: 3)))
        #expect(batch.count == 2)
        #expect(silenceDuration(of: batch[0]) == .seconds(1))
        #expect(spokenPart(of: batch[1])?.string == middlePart)
    }

    /// Every batch recites exactly one part, and it is the last event in the batch.
    @Test func testEveryBatchRecitesOnePart() throws {
        var sequence = makeSequence()
        for _ in 1...3 {
            let batch = try nextBatch(of: &sequence)
            #expect(batch.compactMap { spokenPart(of: $0) }.count == 1)
            let last = try #require(batch.last)
            #expect(spokenPart(of: last) != nil)
        }
    }

    /// Each part of the ballad is recited once, in order.
    @Test func testEachPartIsRecitedInOrder() throws {
        let ballad = makeBallad()
        let performance = Performance(ballad: ballad, speakers: Speakers())
        var sequence = EventsSequence(performance: performance)
        var recited: [String] = []
        for _ in 1...ballad.parts.count {
            let batch = try nextBatch(of: &sequence)
            recited.append(contentsOf: batch.compactMap { spokenPart(of: $0)?.string })
        }
        #expect(recited == ballad.parts.map { $0.string })
    }

    /// The speakers take turns, starting with the second speaker.
    @Test func testSpeakersAlternate() throws {
        let speakers = Speakers()
        let expected = [speakers.secondSpeaker.name, speakers.firstSpeaker.name, speakers.secondSpeaker.name]
        var sequence = EventsSequence(performance: Performance(ballad: makeBallad(), speakers: speakers))
        var names: [String] = []
        for _ in 1...3 {
            let batch = try nextBatch(of: &sequence)
            for event in batch {
                if case .speak(_, let speaker) = event {
                    names.append(speaker.name)
                }
            }
        }
        #expect(names == expected)
    }

    /// Known issue: `next()` never returns `nil`. Once the last part has been recited the cursor
    /// resets and the sequence starts the ballad over, so `Performance.run()` never finishes.
    @Test func testSequenceFinishesAfterTheLastPart() throws {
        let ballad = makeBallad()
        var sequence = EventsSequence(performance: Performance(ballad: ballad, speakers: Speakers()))
        for _ in 1...ballad.parts.count {
            _ = sequence.next()
        }
        withKnownIssue("The sequence restarts the ballad instead of finishing.") {
            if let batch = sequence.next() {
                Issue.record("Expected no further events but got \(batch.map { $0.description }).")
            }
        }
    }
}
