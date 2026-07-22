//
//  TuneTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 05/12/2023.
//

import Testing
@testable import ConnaughtSquare

final class TuneTests {
	var notes: [Note]!
	var tune: Tune!

    init() throws {
		notes = [Note(value: .d3, duration: .quaver),
				 Note(value: .c3, duration: .quaver),
				 Note(value: .b2, duration: .crotchet)]
		tune = Tune("Test", Cycle<Note>(elements: notes))
    }

    deinit {
		notes = nil
		tune = nil
    }

    @Test func testInit() {
        #expect(tune.notes.elements.count == 3)
    }
    
    @Test func testTotalDuration() {
        #expect(tune.totalDuration == .microseconds(notes.reduce(0) { $0 + $1.duration.rawValue}))
    }
    
    @Test func testHighestNoteNumber() {
        #expect(tune.highestNote.value == NoteValue.d3)
    }
    
    @Test func testLowestNoteNumber() {
        #expect(tune.lowestNote.value == NoteValue.b2)
    }
    
    func testMostFrequentNoteNumber() {
        #expect(tune.mostFrequentNote.value == NoteValue.d3)
    }
    
    @Test func testNoteIntervalVectors() {
		let notes = [Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .dSharp2, duration: .quaver),
					 Note(value: .f2, duration: .quaver),
					 Note(value: .gSharp2, duration: .quaver),
					 Note(value: .c3, duration: .quaver),
					 Note(value: .f3, duration: .quaver),
					 Note(value: .b3, duration: .crotchet)]
		let tune = Tune("Untitled", Cycle<Note>(elements: notes))
		let vectors = tune.noteIntervalVectors(width: 3)
		let vector = Vector<NoteInterval>([.level, .level, .level], weight: 1)
        #expect(vectors[vectors.position(of: vector)] == vector)
        #expect(vectors.weight(of: Vector<NoteInterval>([.level, .level, .level])) == 6)
        #expect(vectors.weight(of: Vector<NoteInterval>([.rising(by: 1), .rising(by: 2), .rising(by: 3)])) == 1)
	}
	
    @Test func testNoteDurationVectors() {
		let notes = [Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .quaver),
					 Note(value: .d2, duration: .crotchet),
					 Note(value: .d2, duration: .minim),
					 Note(value: .d2, duration: .breve)]
		let tune = Tune("Untitled", Cycle<Note>(elements: notes))
		let vectors = tune.noteDurationVectors(width: 3)
		let vector = Vector<NoteDuration>([.quaver, .quaver, .quaver], weight: 1)
        #expect(vectors[vectors.position(of: vector)] == vector)
        #expect(vectors.weight(of: Vector<NoteDuration>([.quaver, .quaver, .quaver])) == 7)
        #expect(vectors.weight(of: Vector<NoteDuration>([.crotchet, .minim, .breve])) == 1)
	}

}
