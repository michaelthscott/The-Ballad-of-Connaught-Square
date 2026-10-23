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
        let composer = Composer()
        let performance = Performance(composer: composer, ballad: Ballad(), speakers: Speakers())
        var events = EventsSequence(performance: performance)
        let firstBatch = events.next()
        let batch = try #require(firstBatch)
        #expect(batch.isEmpty == false)
    }

    @Test func testOrchestration() async throws {
        let performance = Performance(composer: Composer(), ballad: Ballad(), speakers: Speakers())
        let orchestration = performance.orchestration(duration: .seconds(1))
        #expect(orchestration.title == "The Ballad of Connaught Square")
        #expect(orchestration.assignments.count == 3)
    }

    /// A performance on a sound bank of its own, so pausing it doesn't pause other tests' notes.
    private func makePerformance() throws -> Performance {
        Performance(composer: Composer(), ballad: Ballad(), speakers: Speakers(), soundBank: try SoundBank())
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

    /// A performance stops by itself once it has recited every part.
    @Test func testPerformanceFinishes() async throws {
        let performance = Performance(composer: Composer(), ballad: Ballad(lines: []), speakers: Speakers(), soundBank: try SoundBank())
        performance.play()
        #expect(performance.state == .playing)
        for _ in 0..<100 where performance.state == .playing {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(performance.state == .stopped)
    }

    /// A performance stopped after an odd number of parts still starts the next one with the second speaker.
    @Test func testPlayResetsSpeakerTurns() async throws {
        let performance = try makePerformance()
        _ = performance.speakers.nextSpeaker
        performance.play()
        performance.stop()
        #expect(performance.speakers.nextSpeaker == performance.speakers.secondSpeaker)
    }

}
