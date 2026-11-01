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
        let performance = Performance(score: .standard, ballad: Ballad(), speakers: Speakers())
        var events = EventsSequence(performance: performance)
        let firstCue = events.next()
        let cue = try #require(firstCue)
        #expect(cue.before.isEmpty == false)
    }

    /// By default the performance follows the bundled score, with a voice for each of its roles.
    @Test func testDefaultScore() async throws {
        let performance = Performance(ballad: Ballad(lines: []))
        #expect(performance.score == Score.bundled)
        #expect(performance.speakers.roles == Score.bundled.voices.roles)
    }

    @Test func testOrchestration() async throws {
        let performance = Performance(score: .standard, ballad: Ballad(), speakers: Speakers())
        let passage = Passage(seconds: 1, instruments: [InstrumentPart(instrument: .violin),
                                                        InstrumentPart(instrument: .viola),
                                                        InstrumentPart(instrument: .cello)])
        let orchestration = performance.arranger.orchestration(for: passage, lasting: .seconds(1))
        #expect(orchestration.title == "The Ballad of Connaught Square")
        #expect(orchestration.assignments.count == 3)
    }

    /// A performance on a sound bank of its own, so pausing it doesn't pause other tests' notes.
    private func makePerformance() throws -> Performance {
        Performance(score: .standard, ballad: Ballad(), speakers: Speakers(), soundBank: try SoundBank())
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

    /// A viola that lasts as long as the part.
    private func violaAccompaniment() -> Orchestration {
        let composer = Composer()
        return Orchestration(title: "Accompaniment", assignments: [composer.composeAssignment(instrument: Instrument(name: .viola), duration: .seconds(1))])
    }

    /// Accompaniment lasting as long as the part stops when the recitation finishes.
    @Test func testAccompanimentStopsWithTheRecitation() async throws {
        let soundBank = try SoundBank()
        let recitation = Task<Void, Never> {
            try? await Task.sleep(for: .milliseconds(500))
        }
        let clock = ContinuousClock()
        let elapsed = await clock.measure {
            await Performance.accompany(recitation, with: violaAccompaniment(), on: soundBank)
        }
        // It plays through the recitation, and stops within a note of its end.
        #expect(elapsed >= .milliseconds(500))
        #expect(elapsed < .seconds(2))
        await soundBank.stopEngine()
    }

    /// Accompaniment for a recitation that has already finished doesn't hold the performance up.
    @Test func testAccompanimentAfterTheRecitation() async throws {
        let soundBank = try SoundBank()
        let recitation = Task {}
        await recitation.value
        let elapsed = await ContinuousClock().measure {
            await Performance.accompany(recitation, with: violaAccompaniment(), on: soundBank)
        }
        #expect(elapsed < .seconds(1))
        await soundBank.stopEngine()
    }

    /// A performance stops by itself once it has recited every part.
    @Test func testPerformanceFinishes() async throws {
        let performance = Performance(score: .standard, ballad: Ballad(lines: []), speakers: Speakers(), soundBank: try SoundBank())
        performance.play()
        #expect(performance.state == .playing)
        for _ in 0..<100 where performance.state == .playing {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(performance.state == .stopped)
    }

}
