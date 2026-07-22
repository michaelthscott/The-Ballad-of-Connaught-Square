//
//  InstrumentTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 05/12/2023.
//

import Testing
@testable import ConnaughtSquare

final class InstrumentTests {
	var tune: Tune!

    init() throws {
        tune = Tune("Test", [Note(value: .cSharp3, duration: .crotchet), Note(value: .c3, duration: .crotchet)])
    }

    @Test func testName() {
        #expect(Instrument(name: .clarinet).name == .clarinet)
    }
    
    @Test func testInstruments() {
        #expect(Instrument(name: .clarinet).name == .clarinet)
        #expect(Instrument(name: .bassoon).name == .bassoon)
    }
    
    @Test func testSoundBank() {
        #expect(Instrument(name: .electricPiano1).play(notes: tune.notes, duration: .seconds(1)).count == 1)
    }
	
    @Test func testPlayed() {
        #expect(Instrument(name: .marimba).play(notes: tune.notes, duration: tune.totalDuration * 2).count == tune.notes.elements.count * 2)
    }
        
}
