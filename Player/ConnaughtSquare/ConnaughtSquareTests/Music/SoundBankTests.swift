//
//  SoundBankTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 06/04/2025.
//

import Testing
@testable import ConnaughtSquare

struct SoundBankTests {
    let soundBank: SoundBank!
    
    init() throws {
        soundBank = try SoundBank.shared
    }

    @Test func testResource() async throws {
        #expect(throws: SoundBankError.failedToFindSoundBank.self) {
            try SoundBank(resource: "", suffix: "")
        }
    }
    
    @Test func testLoadInstrument() async throws {
        #expect(throws: Never.self) {
            try soundBank.loadInstrument(.electricPiano1)
        }
    }

    @Test func testStartEngine() async throws {
        #expect(throws: Never.self) {
            try soundBank.startEngine()
        }
    }

    @Test func testStopEngine() async throws {
        #expect(throws: Never.self) {
            soundBank.stopEngine()
        }
    }

    @Test func testPlayNote() async throws {
        #expect(throws: Never.self) {
            try soundBank.loadInstrument(.electricPiano1)
            soundBank.play(note: Note(value: .a2, on: .f, off: .f, duration: .crotchet))
        }
    }
    
    @Test func testPlayNotes() async throws {
        let cycle = Cycle(elements: [Note(value: .a2, duration: .quaver), Note(value: .a3, duration: .crotchet), Note(value: .b2, duration: .quaver)])
        let total = NoteDuration.quaver.duration + NoteDuration.crotchet.duration + NoteDuration.quaver.duration
        #expect(try soundBank.play(notes: cycle, duration: total).count == 3)
    }

}
