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
        await soundBank.stopEngine()
    }

    @Test func testPlayNote() async throws {
        try await soundBank.loadInstrument(.electricPiano1)
        await soundBank.play(note: Note(value: .a2, on: .f, off: .f, duration: .crotchet))
    }
    
    @Test func testPlayNotes() async throws {
        let cycle = Cycle(elements: [Note(value: .a2, duration: .quaver), Note(value: .a3, duration: .crotchet), Note(value: .b2, duration: .quaver)])
        let total = NoteDuration.quaver.duration + NoteDuration.crotchet.duration + NoteDuration.quaver.duration
        let played = try await soundBank.play(notes: cycle, duration: total, instrument: .electricPiano1)
        #expect(played.count == 3)
    }

}
