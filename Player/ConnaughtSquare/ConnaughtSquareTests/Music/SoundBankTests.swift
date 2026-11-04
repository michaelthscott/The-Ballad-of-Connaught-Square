//
//  SoundBankTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 06/04/2025.
//

import Testing
@testable import ConnaughtSquare

struct SoundBankTests {
    let soundBank = SoundBank.shared

    @Test func testResource() async throws {
        #expect(throws: SoundBankError.failedToFindSoundBank) {
            try SoundBank(resource: "", suffix: "")
        }
    }
    
    @Test func testLoadInstrument() async throws {
        await #expect(throws: Never.self) {
            try await soundBank.loadInstrument(.electricPiano1)
        }
    }

    @Test func testStartEngine() async throws {
        await #expect(throws: Never.self) {
            try await soundBank.startEngine()
        }
    }

    @Test func testStopEngine() async throws {
        // A sound bank of its own, as stopping releases the instruments other tests have loaded.
        let soundBank = try SoundBank()
        await soundBank.stopEngine()
    }

    /// Stopping the engine empties the samplers' presets, so it releases the instruments, and
    /// playing again loads them afresh rather than playing the sampler's default sound.
    @Test func testStopEngineReleasesInstruments() async throws {
        let soundBank = try SoundBank()
        let cycle = Cycle(elements: [Note(value: .a2, duration: .quaver)])
        _ = try await soundBank.play(notes: cycle, duration: NoteDuration.quaver.duration, instrument: .violin)
        #expect(await soundBank.loadedInstruments == [.violin])
        await soundBank.stopEngine()
        #expect(await soundBank.loadedInstruments.isEmpty)
        let played = try await soundBank.play(notes: cycle, duration: NoteDuration.quaver.duration, instrument: .violin)
        #expect(played.count == 1)
        #expect(await soundBank.loadedInstruments == [.violin])
        #expect(await soundBank.isEngineRunning)
        await soundBank.stopEngine()
    }

    @Test func testPlayNote() async throws {
        try await soundBank.loadInstrument(.electricPiano1)
        await soundBank.play(note: Note(value: .a2, on: .f, duration: .crotchet), instrument: .electricPiano1)
    }

    /// Notes at a volume of 0 are silent, but still take their time.
    @Test func testPlaySilently() async throws {
        let soundBank = try SoundBank()
        let cycle = Cycle(elements: [Note(value: .a2, duration: .quaver)])
        let played = try await soundBank.play(notes: cycle, duration: NoteDuration.quaver.duration, instrument: .viola, volume: 0)
        #expect(played.count == 1)
        await soundBank.stopEngine()
    }

    @Test func testLoadInstrumentsSeparately() async throws {
        try await soundBank.loadInstrument(.violin)
        try await soundBank.loadInstrument(.cello)
        try await soundBank.loadInstrument(.violin)
        // Other tests share the sound bank, so it may hold further instruments.
        #expect(await soundBank.loadedInstruments.isSuperset(of: [.violin, .cello]))
    }

    @Test func testPlayInstrumentsConcurrently() async throws {
        // Both instruments play the same pitch at the same time, so neither should cut the other short.
        let cycle = Cycle(elements: [Note(value: .a2, duration: .quaver), Note(value: .a2, duration: .crotchet)])
        let total = NoteDuration.quaver.duration + NoteDuration.crotchet.duration
        async let violin = soundBank.play(notes: cycle, duration: total, instrument: .violin)
        async let cello = soundBank.play(notes: cycle, duration: total, instrument: .cello)
        let played = try await (violin, cello)
        #expect(played.0.count == 2)
        #expect(played.1.count == 2)
        #expect(await soundBank.loadedInstruments.isSuperset(of: [.violin, .cello]))
    }
    
    @Test func testPlayNotes() async throws {
        let cycle = Cycle(elements: [Note(value: .a2, duration: .quaver), Note(value: .a3, duration: .crotchet), Note(value: .b2, duration: .quaver)])
        let total = NoteDuration.quaver.duration + NoteDuration.crotchet.duration + NoteDuration.quaver.duration
        let played = try await soundBank.play(notes: cycle, duration: total, instrument: .electricPiano1)
        #expect(played.count == 3)
    }

    /// Playing from a cycle in place leaves it at the next note, so the melody can carry on from there.
    @Test func testPlayNotesCarriesOn() async throws {
        var cycle = Cycle(elements: [Note(value: .a2, duration: .quaver), Note(value: .a3, duration: .quaver), Note(value: .b2, duration: .quaver)])
        let first = try await soundBank.play(notes: &cycle, instrument: .electricPiano1, volume: 0.5) { $0 < NoteDuration.quaver.duration }
        let second = try await soundBank.play(notes: &cycle, instrument: .electricPiano1) { $0 < NoteDuration.quaver.duration }
        #expect(first.map(\.value) == [.a2])
        #expect(second.map(\.value) == [.a3])
    }

    @Test func testPauseAndResumeEngine() async throws {
        // A sound bank of its own, so pausing it doesn't pause other tests' notes.
        let soundBank = try SoundBank()
        try await soundBank.startEngine()
        await soundBank.pauseEngine()
        try await soundBank.resumeEngine()
        await soundBank.stopEngine()
    }

    @Test func testStartEngineWhilePaused() async throws {
        // An instrument that starts playing while the engine is paused mustn't unpause it.
        let soundBank = try SoundBank()
        try await soundBank.startEngine()
        await soundBank.pauseEngine()
        try await soundBank.startEngine()
        #expect(await !soundBank.isEngineRunning)
        try await soundBank.resumeEngine()
        #expect(await soundBank.isEngineRunning)
        await soundBank.stopEngine()
    }

}
