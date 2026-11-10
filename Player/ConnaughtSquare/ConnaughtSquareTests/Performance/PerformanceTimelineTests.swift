//
//  PerformanceTimelineTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 10/11/2026.
//

import Testing
import AVFoundation
@testable import ConnaughtSquare

/// Whole performances of a small ballad, timed on a manual clock, with the parts recited by a
/// stand-in that records them rather than by real speech.
@MainActor
struct PerformanceTimelineTests {
    let clock = ManualClock()
    let speech: RecordingSpeech
    let performance: Performance

    init() throws {
        let soundBank = try SoundBank(clock: clock)
        // Long enough for the music opening a line to finish while its part is recited, whatever notes it plays.
        speech = RecordingSpeech(clock: clock, gate: soundBank.pauseGate, length: .seconds(10))
        performance = Performance(score: .timeline, ballad: .test(), speakers: Speakers.cached(), soundBank: soundBank, speech: speech)
    }

    /// The cue for each part, in the order the performance recites them.
    private func cues() -> [Cue] {
        var sequence = EventsSequence(performance: performance)
        var cues: [Cue] = []
        while let cue = sequence.next() {
            cues.append(cue)
        }
        return cues
    }

    /// When each part should start being recited, from the start of the performance.
    ///
    /// Each cue rests as the score says, plays any intermission, then waits for its recitation to
    /// start. The timeline score leaves room for its longest notes, so the intermission lasts its
    /// length and each line's music stops before its part has been recited, and the next cue follows
    /// straight on from the end of the recitation.
    private func expectedStarts() -> [Duration] {
        var time = Duration.zero
        var starts: [Duration] = []
        for cue in cues() {
            time += cue.balladTitleRest + cue.intermissionLength + cue.cantoTitleRest + cue.recitationStart
            starts.append(time)
            time += speech.length
        }
        return starts
    }

    /// Runs the clock until the performance stops by itself.
    /// - Returns: How long the clock ran for.
    private func finish() async -> Duration {
        let performance = performance
        return await clock.measure { @MainActor in
            while performance.state != .stopped {
                try? await Task.sleep(for: .milliseconds(1))
            }
        }
    }

    /// Waits in real time until the condition holds, for the performance to get ready, which isn't
    /// timed on the clock.
    /// - Returns: Whether the condition held.
    private func waitUntil(within limit: Duration = .seconds(5), _ condition: () -> Bool) async throws -> Bool {
        let deadline = ContinuousClock.now + limit
        while !condition() {
            guard ContinuousClock.now < deadline else { return false }
            try await Task.sleep(for: .milliseconds(1))
        }
        return true
    }

    @Test func testRecitesEveryPartInOrder() async throws {
        let cues = cues()
        #expect(cues.count == 3)
        performance.play()
        _ = await finish()
        #expect(speech.recitations.map(\.string) == cues.map(\.part.string))
        #expect(speech.recitations.map(\.voice) == cues.map(\.speaker.voice.identifier))
        #expect(speech.recitations.map(\.pan) == cues.map(\.pan))
        // The voices are readied once, before the introduction.
        #expect(speech.warmUps == [performance.speakers.voices.map(\.voice.identifier)])
    }

    @Test func testRecitationsStartOnTime() async throws {
        let expected = expectedStarts()
        // The ballad's title rest, the introduction and the canto's title rest come before the first part.
        let score = Score.timeline
        #expect(expected.first == .seconds(score.balladTitleRest + score.introduction.seconds + score.cantoTitleRest))
        performance.play()
        _ = await finish()
        #expect(speech.recitations.map(\.start.offset) == expected)
    }

    /// The ballad's title shows before the introduction, and the canto's after it, both before anything is recited.
    @Test func testTitlesAreAnnouncedBeforeTheRecitation() async throws {
        performance.play()
        #expect(try await waitUntil { performance.isTitleAnnounced })
        #expect(performance.announcedCantoCount == 0)
        // Past the title rest and the introduction, into the canto's title rest.
        let score = Score.timeline
        await clock.advance(by: .seconds(score.balladTitleRest + score.introduction.seconds + score.cantoTitleRest / 2))
        #expect(performance.announcedCantoCount == 1)
        #expect(speech.recitations.isEmpty)
        await clock.advance(by: .seconds(1))
        #expect(speech.recitations.count == 1)
        performance.stop()
    }

    /// Pausing during a part holds it, and every later part starts that much later.
    @Test func testPauseHoldsTheRecitation() async throws {
        let expected = expectedStarts()
        let pause = Duration.seconds(10)
        performance.play()
        #expect(try await waitUntil { performance.isTitleAnnounced })
        // Part-way through the first part.
        await clock.advance(by: expected[0] + .seconds(1))
        #expect(speech.recitations.count == 1)
        performance.pause()
        await clock.advance(by: pause)
        #expect(speech.recitations.count == 1)
        #expect(performance.spokenPartCount == 1)
        performance.resume()
        _ = await finish()
        #expect(speech.recitations.map(\.start.offset) == [expected[0]] + expected.dropFirst().map { $0 + pause })
    }

    /// Stopping during a part ends it, and nothing more is recited.
    @Test func testStopEndsTheRecitation() async throws {
        let expected = expectedStarts()
        performance.play()
        #expect(try await waitUntil { performance.isTitleAnnounced })
        await clock.advance(by: expected[0] + .seconds(1))
        performance.stop()
        #expect(speech.stopCount == 1)
        await clock.advance(by: .seconds(30))
        #expect(speech.recitations.count == 1)
        #expect(performance.state == .stopped)
    }

    /// The performance stops by itself as the last part finishes.
    @Test func testFinishesAfterTheLastPart() async throws {
        let expected = try #require(expectedStarts().last)
        performance.play()
        let elapsed = await finish()
        #expect(elapsed == expected + speech.length)
        #expect(performance.state == .stopped)
    }
}

private extension Score {
    /// A short score: a second's rest after the ballad's title, an introduction of half a second of
    /// viola, and a second's rest after the canto's title. Later lines open with half a second of
    /// viola, recited a second in, and later parts with half a second's silence.
    ///
    /// The composer chooses the notes' lengths, and a note sounds in full even past the end of its
    /// stretch, so the introduction leaves room after its viola for the longest note.
    static let timeline = Score(title: "Timeline",
                                balladTitleRest: 1,
                                introduction: Intermission(tracks: [.viola(seconds: 0.5)], seconds: 0.5 + longestNote),
                                canto: Intermission(),
                                cantoTitleRest: 1,
                                stanza: Intermission(),
                                firstLine: Interlude(),
                                line: Interlude(recitationStart: 1, tracks: [.viola(seconds: 0.5)]),
                                part: Interlude(recitationStart: 0.5))
}

/// The length of the longest note in seconds.
private let longestNote = NoteDuration.allCases.max().map { Double($0.rawValue) / 1_000_000 } ?? 0

private extension Track {
    /// The viola plays from the start for the seconds.
    static func viola(seconds: Double) -> Track {
        Track(instruments: [.viola], stretches: [Stretch(start: .seconds(0), end: .seconds(seconds))])
    }
}
