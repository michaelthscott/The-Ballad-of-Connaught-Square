//
//  AssignmentTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/02/2024.
//

import Testing
@testable import ConnaughtSquare

struct AssignmentTests {
    let instrument: Instrument!
    let cycle: Cycle<Note>!
    let assignment: Assignment!
    
    init() async throws {
        instrument = Instrument(name: .accordion)
        cycle = Cycle(elements: [Note(value: .a2, duration: .quaver), Note(value: .a3, duration: .crotchet), Note(value: .b2, duration: .quaver)])
        assignment = Assignment(instrument: instrument, notes: cycle)
    }
    
    @Test func testAssignment() async throws {
        #expect(assignment.instrument == instrument)
        #expect(assignment.notes == cycle)
    }
    
    @Test func testPlay() async throws {
        let total = NoteDuration.quaver.duration + NoteDuration.crotchet.duration + NoteDuration.quaver.duration
        #expect(assignment.play(duration: NoteDuration.quaver.duration).count == 1)
        #expect(assignment.play(duration: total).count == 3)
        #expect(assignment.play(duration: total * 2 + NoteDuration.quaver.duration).count == 7)
        #expect(assignment.play(duration: total * 3 + NoteDuration.quaver.duration + NoteDuration.crotchet.duration).count == 11)
    }
    
}
