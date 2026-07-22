//
//  WordTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Testing
@testable import ConnaughtSquare

final class WordTests {
	var lexicon: Lexicon!
	
	init() throws {
		lexicon = Lexicon.shared
	}

	deinit {
		lexicon = nil
	}
	
    @Test func testWord() {
        #expect(lexicon.word("notaword") == nil)
    }
    
    @Test func testSyllables() {
        guard let word = lexicon.word("agreements") else {
            Issue.record("Failed to find word 'agreements'")
            return
        }
        // [AH0, GR-IY1, M-AH0-NTS]
        #expect(word.syllables.count == 3)
    }
    
    @Test func testRhyme() {
        guard let word = lexicon.word("agreements"), let rhyme = word.rhyme else {
            Issue.record("Failed to find word 'agreements'")
            return
        }
        // [AH0, N, T, S]
        #expect(rhyme.description == "AH0-N-T-S")
    }
	
    @Test func testEquatable() {
        #expect(lexicon.word("BELL") == lexicon.word("BELL"))
        #expect(lexicon.word("BELL") == lexicon.word("bell"))
	}
	
    @Test func testFinalStressedSyllable() {
        #expect(lexicon.word("BELL")?.finalStressedSyllable?.description == "B-EH1-L")
        #expect(lexicon.word("TELL")?.finalStressedSyllable?.description == "T-EH1-L")
	}
	
    @Test func testLastSyllables() {
        #expect(lexicon.word("AGREEMENTS")?.finalSyllable?.description == "M-AH0-NTS")
        #expect(lexicon.word("AGREEMENTS")?.penultimateSyllable?.description == "GR-IY1")
        #expect(lexicon.word("AGREEMENTS")?.antepenultimateSyllable?.description == "AH0")
	}
	
    @Test func testLastStressedSyllables() {
        #expect(lexicon.word("AGREEMENTS")?.finalStressedSyllable == nil)
        #expect(lexicon.word("AGREEMENTS")?.penultimateStressedSyllable?.description == "GR-IY1")
        #expect(lexicon.word("AGREEMENTS")?.antepenultimateStressedSyllable == nil)
	}
}
