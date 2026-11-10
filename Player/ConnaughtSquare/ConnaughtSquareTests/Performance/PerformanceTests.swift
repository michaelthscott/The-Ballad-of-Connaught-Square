//
//  PerformanceTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 30/03/2025.
//

import Testing
@testable import ConnaughtSquare

@MainActor
struct PerformanceTests {

    @Test func testPerformance() async throws {
        let performance = Performance(score: .standard, ballad: Ballad(), speakers: Speakers.cached())
        var events = EventsSequence(performance: performance)
        let firstCue = events.next()
        let cue = try #require(firstCue)
        #expect(cue.intermission.isEmpty == false)
    }

    /// By default the performance follows the bundled score, with a voice for each of the standard roles.
    @Test func testDefaultScore() async throws {
        let performance = Performance(ballad: Ballad(lines: []))
        #expect(performance.score == Score.bundled)
        #expect(performance.speakers.roles == VoiceNotation.standard.roles)
    }

    @Test func testEvents() async throws {
        let performance = Performance(score: .standard, ballad: Ballad(), speakers: Speakers.cached())
        let events = performance.arranger.events(for: Score.standard.line, partDuration: .seconds(1))
        #expect(events.map(\.instrument.name) == [.violin, .viola, .cello])
    }

    /// A performance on a sound bank of its own, so pausing it doesn't pause other tests' notes.
    private func makePerformance() throws -> Performance {
        Performance(score: .standard, ballad: Ballad(), speakers: Speakers.cached(), soundBank: try SoundBank())
    }

    @Test func testInitialState() async throws {
        let performance = try makePerformance()
        #expect(performance.state == .stopped)
    }

    @Test func testPlayPauseResumeStop() async throws {
        let performance = try makePerformance()
        performance.play()
        #expect(performance.state == .playing)
        performance.pause()
        #expect(performance.state == .paused)
        performance.play()
        #expect(performance.state == .playing)
        performance.stop()
        #expect(performance.state == .stopped)
    }

    @Test func testStopWhilePaused() async throws {
        let performance = try makePerformance()
        performance.play()
        performance.pause()
        performance.stop()
        #expect(performance.state == .stopped)
    }

    @Test func testPauseAndResumeWhileStopped() async throws {
        let performance = try makePerformance()
        performance.pause()
        #expect(performance.state == .stopped)
        performance.resume()
        #expect(performance.state == .stopped)
    }

    @Test func testPlayClearsRecitedParts() async throws {
        let performance = try makePerformance()
        performance.ballad.isRecited = true
        performance.play()
        performance.stop()
        #expect(performance.ballad.isRecited == false)
    }

    /// Waits until the condition holds, checking every 50ms, or until the time runs out.
    /// - Returns: Whether the condition held.
    private func waitUntil(within limit: Duration = .seconds(5), _ condition: () -> Bool) async throws -> Bool {
        let deadline = ContinuousClock.now + limit
        while !condition() {
            guard ContinuousClock.now < deadline else { return false }
            try await Task.sleep(for: .milliseconds(50))
        }
        return true
    }

    /// The ballad's title shows as the performance starts, and performing again after stopping clears
    /// it for a moment before it shows again.
    @Test func testPlayAgainClearsTheTitle() async throws {
        let clock = ManualClock()
        let performance = Performance(score: .standard, ballad: Ballad(), speakers: Speakers.cached(), soundBank: try SoundBank(clock: clock))
        performance.play()
        #expect(try await waitUntil { performance.isTitleAnnounced })
        performance.stop()
        #expect(performance.isTitleAnnounced)
        performance.play()
        #expect(!performance.isTitleAnnounced)
        // The title stays cleared until the clock has moved on by the clearing time.
        await clock.advance(by: Performance.titleClearing / 2)
        #expect(!performance.isTitleAnnounced)
        await clock.advance(by: Performance.titleClearing / 2)
        #expect(try await waitUntil { performance.isTitleAnnounced })
        performance.stop()
    }

    /// The tests that time playing on the sound bank. Each times against a clock of its own, so
    /// their notes can't be held up by each other's.
    @MainActor struct Playback {

        /// The viola playing quavers through the stretches.
        private func viola(_ stretches: [Stretch]) -> Event {
            Event(instrument: Instrument(name: .viola),
                  notes: Cycle(elements: [Note(value: .a2, duration: .quaver), Note(value: .c3, duration: .quaver)]),
                  stretches: stretches)
        }

        /// How long the viola takes to play alongside a recitation of the given length, on a sound bank
        /// of its own, timed on a manual clock. The viola is loaded first, so the time doesn't include loading it.
        private func timePlaying(_ stretches: [Stretch], recitation length: Duration = .zero) async throws -> Duration {
            let clock = ManualClock()
            let soundBank = try SoundBank(clock: clock)
            try await soundBank.loadInstrument(.viola)
            try await soundBank.startEngine()
            let viola = viola(stretches)
            let elapsed = await clock.measure {
                let recitation = Task<Void, Never> {
                    try? await clock.sleep(for: length)
                }
                _ = await Performance.play([viola], on: soundBank, alongside: recitation)
            }
            await soundBank.stopEngine()
            return elapsed
        }

        /// An instrument playing until after the recitation plays through it, then on for the time given.
        @Test func testInstrumentPlaysOnAfterTheRecitation() async throws {
            let elapsed = try await timePlaying([Stretch(start: .seconds(0), end: .afterRecitation(seconds: 0.5))], recitation: .milliseconds(500))
            // It plays through the recitation and half a second more, the recitation within a note.
            #expect(elapsed >= .seconds(1))
            #expect(elapsed <= .seconds(1) + NoteDuration.quaver.duration)
        }

        /// An instrument playing until a time from the start stops then, within a note.
        @Test func testInstrumentStopsOnTime() async throws {
            let elapsed = try await timePlaying([Stretch(start: .seconds(0), end: .seconds(1))])
            // Two quavers fill the second exactly.
            #expect(elapsed == .seconds(1))
        }

        /// An instrument rests in a gap between its stretches.
        @Test func testInstrumentRestsBetweenStretches() async throws {
            let elapsed = try await timePlaying([Stretch(start: .seconds(0), end: .seconds(0.5)), Stretch(start: .seconds(1), end: .seconds(1.5))])
            #expect(elapsed == .milliseconds(1500))
        }

        /// Playing the events gives back where each instrument's melody stopped, for the next part to carry on.
        @Test func testPlayingGivesBackTheMelodies() async throws {
            let clock = ManualClock()
            let soundBank = try SoundBank(clock: clock)
            try await soundBank.loadInstrument(.viola)
            try await soundBank.startEngine()
            let event = Event(instrument: Instrument(name: .viola),
                              notes: Cycle(elements: [Note(value: .a2, duration: .quaver), Note(value: .c3, duration: .quaver), Note(value: .e3, duration: .quaver)]),
                              stretches: [Stretch(start: .seconds(0), end: .seconds(1))])
            let recitation = Task<Void, Never> {}
            let playing = Task {
                await Performance.play([event], on: soundBank, alongside: recitation)
            }
            _ = await clock.measure {
                _ = await playing.value
            }
            var melodies = await playing.value
            await soundBank.stopEngine()
            // A second of quavers is two notes, so the melody carries on from the third.
            #expect(melodies[.viola]?.next().value == .e3)
        }

        /// An instrument playing until the end of a recitation that has already finished doesn't hold the performance up.
        @Test func testInstrumentAfterTheRecitation() async throws {
            let elapsed = try await timePlaying([Stretch(start: .seconds(0), end: .endOfRecitation)])
            // A note can start before the instrument sees that the recitation has finished, but no more.
            #expect(elapsed <= NoteDuration.quaver.duration)
        }

        /// An intermission lasts for its length, even after its instruments have stopped.
        @Test func testIntermissionLastsItsLength() async throws {
            let clock = ManualClock()
            let soundBank = try SoundBank(clock: clock)
            try await soundBank.loadInstrument(.viola)
            try await soundBank.startEngine()
            let viola = viola([Stretch(start: .seconds(0), end: .seconds(0.5))])
            let elapsed = await clock.measure {
                await Performance.playIntermission([viola], lasting: .milliseconds(1500), on: soundBank)
            }
            await soundBank.stopEngine()
            #expect(elapsed == .milliseconds(1500))
        }
    }

    /// A performance stops by itself once it has recited every part.
    @Test func testPerformanceFinishes() async throws {
        let performance = Performance(score: .standard, ballad: Ballad(lines: []), speakers: Speakers.cached(), soundBank: try SoundBank())
        performance.play()
        #expect(performance.state == .playing)
        for _ in 0..<100 where performance.state == .playing {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(performance.state == .stopped)
    }

}
