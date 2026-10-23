//
//  BalladCursorTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 10/04/2025.
//

import Testing
@testable import ConnaughtSquare

struct BalladCursorTests {

    @Test func testNext() async throws {
        var sequence = BalladCursorSequence(ballad: Ballad())
        #expect(sequence.cursor?.cantoIndex == 0)
        #expect(sequence.cursor?.stanzaIndex == 0)
        #expect(sequence.cursor?.lineIndex == 1000)
        #expect(sequence.cursor?.partIndex == 0)
        #expect(sequence.next() != nil)
        #expect(sequence.cursor?.lineIndex == 1001)
        #expect(sequence.next() != nil)
        #expect(sequence.cursor?.lineIndex == 1002)
        #expect(sequence.next() != nil)
        #expect(sequence.cursor?.lineIndex == 1003)
        #expect(sequence.next() != nil)
        #expect(sequence.cursor?.stanzaIndex == 1)
        #expect(sequence.cursor?.lineIndex == 1004)
        #expect(sequence.next() != nil)
        #expect(sequence.cursor?.stanzaIndex == 1)
        #expect(sequence.cursor?.lineIndex == 1005)
    }

    @Test func testCurrentPart() async throws {
        var sequence = BalladCursorSequence(ballad: Ballad())
        var string = sequence.currentPart?.string
        #expect(string == "Buying, and buying brand new cars.")
        while sequence.next() != nil {
            string = sequence.currentPart?.string
        }
        #expect(string == "Woah.")
    }

    /// Once the last part has been passed the sequence stays finished rather than starting again.
    @Test func testFinishesAfterTheLastPart() async throws {
        let ballad = Ballad()
        var sequence = BalladCursorSequence(ballad: ballad)
        for _ in 1..<ballad.parts.count {
            #expect(sequence.next() != nil)
        }
        #expect(sequence.next() == nil)
        #expect(sequence.cursor == nil)
        #expect(sequence.currentPart == nil)
        #expect(sequence.next() == nil)
        #expect(sequence.isStartOfBallad == false)
    }

    /// A ballad with no parts has no cursor, rather than crashing.
    @Test func testEmptyBallad() async throws {
        var sequence = BalladCursorSequence(ballad: Ballad(lines: []))
        #expect(sequence.cursor == nil)
        #expect(sequence.currentPart == nil)
        #expect(sequence.remainingParts == 0)
        #expect(sequence.isStartOfBallad == false)
        #expect(sequence.isStartOfLine == false)
        #expect(sequence.next() == nil)
    }

}
