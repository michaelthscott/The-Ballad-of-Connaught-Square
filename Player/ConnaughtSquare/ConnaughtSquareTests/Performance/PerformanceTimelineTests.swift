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
        speech = RecordingSpeech(clock: clock, gate: soundBank.pauseGate)
        // Seeded, so that the test's own sequence of cues composes the music the performance plays.
        performance = Performance(score: .timeline, ballad: .test(), speakers: Speakers.cached(), soundBank: soundBank, speech: speech,
                                  randomNumberGenerator: SeededRandomNumberGenerator(seed: 1))
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

    /// When things should happen in the performance, from its start.
    struct Timeline {
        /// When each canto's title shows.
        var cantoTitles: [Duration] = []
        /// When each part starts being recited.
        var starts: [Duration] = []
        /// When the performance finishes.
        var end: Duration = .zero
    }

    /// When things should happen in the performance, worked out from its cues.
    ///
    /// Each cue rests as the score says, then plays any intermission, which lasts its length or until
    /// its music finishes, whichever is later. The canto's title shows and it rests again. Then the
    /// cue's music starts, the part is recited when the score says, and the next cue follows once
    /// both have finished.
    private func timeline() -> Timeline {
        var timeline = Timeline()
        var time = Duration.zero
        for cue in cues() {
            time += cue.balladTitleRest
            time += max(cue.intermissionLength, cue.intermission.map(Self.end(of:)).max() ?? .zero)
            if cue.cantoIndex != nil {
                timeline.cantoTitles.append(time)
            }
            time += cue.cantoTitleRest
            let start = time + cue.recitationStart
            timeline.starts.append(start)
            time += max(cue.recitationStart + speech.length, cue.events.map(Self.end(of:)).max() ?? .zero)
        }
        timeline.end = time
        return timeline
    }

    /// How long after it starts an event playing one stretch from the start finishes. Each note
    /// sounds in full, so the event plays on until the first note to end at or after the stretch's end.
    private static func end(of event: Event) -> Duration {
        guard event.stretches.count == 1, let stretch = event.stretches.first,
              case .seconds(0) = stretch.start, case .seconds(let seconds) = stretch.end else {
            Issue.record("The timeline only works out events playing one stretch from the start")
            return .zero
        }
        var notes = event.notes
        var played = Duration.zero
        while played < .seconds(seconds) {
            played += notes.next().duration.duration
        }
        return played
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
        let timeline = timeline()
        // With this seed, the introduction's last note runs on past its length, which the first part waits for.
        let score = Score.timeline
        #expect(try #require(timeline.cantoTitles.first) > .seconds(score.balladTitleRest + score.introduction.seconds))
        performance.play()
        _ = await finish()
        #expect(speech.recitations.map(\.start.offset) == timeline.starts)
    }

    /// The ballad's title shows before the introduction, and the canto's after it, both before anything is recited.
    @Test func testTitlesAreAnnouncedBeforeTheRecitation() async throws {
        performance.play()
        #expect(try await waitUntil { performance.isTitleAnnounced })
        #expect(performance.announcedCantoCount == 0)
        // Past the title rest and the introduction, into the canto's title rest.
        let cantoTitle = try #require(timeline().cantoTitles.first)
        await clock.advance(by: cantoTitle + .seconds(Score.timeline.cantoTitleRest / 2))
        #expect(performance.announcedCantoCount == 1)
        #expect(speech.recitations.isEmpty)
        await clock.advance(by: .seconds(1))
        #expect(speech.recitations.count == 1)
        performance.stop()
    }

    /// Pausing during a part holds it, and every later part starts that much later.
    @Test func testPauseHoldsTheRecitation() async throws {
        let expected = timeline().starts
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
        let expected = timeline().starts
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
        let expected = timeline().end
        performance.play()
        let elapsed = await finish()
        #expect(elapsed == expected)
        #expect(performance.state == .stopped)
    }
}

private extension Score {
    /// A short score: a second's rest after the ballad's title, an introduction of two seconds of
    /// viola, and a second's rest after the canto's title. Later lines open with a second of viola,
    /// recited a second in, and later parts with half a second's silence.
    static let timeline = Score(title: "Timeline",
                                balladTitleRest: 1,
                                introduction: Intermission(tracks: [.viola(seconds: 2)]),
                                canto: Intermission(),
                                cantoTitleRest: 1,
                                stanza: Intermission(),
                                firstLine: Interlude(),
                                line: Interlude(recitationStart: 1, tracks: [.viola(seconds: 1)]),
                                part: Interlude(recitationStart: 0.5))
}

private extension Track {
    /// The viola plays from the start for the seconds.
    static func viola(seconds: Double) -> Track {
        Track(instruments: [.viola], stretches: [Stretch(start: .seconds(0), end: .seconds(seconds))])
    }
}
