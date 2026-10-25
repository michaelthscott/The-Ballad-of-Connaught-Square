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

    @Test func testPerfectRhyme() {
        // The leading consonants of the stressed syllable are left out.
        #expect(lexicon.word("BELL")?.perfectRhyme(syllablesFromEnd: 1)?.description == "EH1-L")
        #expect(lexicon.word("BELL")?.perfectRhyme(syllablesFromEnd: 1) == lexicon.word("TELL")?.perfectRhyme(syllablesFromEnd: 1))
        // The syllables after the stressed one are included.
        #expect(lexicon.word("AGREEMENTS")?.perfectRhyme(syllablesFromEnd: 2)?.description == "IY1-M-AH0-N-T-S")
        // Unstressed syllables, and words that are too short, have no perfect rhyme.
        #expect(lexicon.word("AGREEMENTS")?.perfectRhyme(syllablesFromEnd: 1) == nil)
        #expect(lexicon.word("BELL")?.perfectRhyme(syllablesFromEnd: 2) == nil)
        #expect(lexicon.word("BELL")?.perfectRhyme(syllablesFromEnd: 0) == nil)
	}

    @Test func testDactylicPerfectRhyme() {
        func word(_ string: String, onset: [SpeechSound]) -> Word {
            let tail: [Phoneme] = [Phoneme(sound: .EH, stress: .primaryStress), Phoneme(sound: .N), Phoneme(sound: .D), Phoneme(sound: .ER, stress: .noStress), Phoneme(sound: .L), Phoneme(sound: .IY, stress: .noStress)]
            return Word(string: string, pronunciation: Pronunciation(phonemes: onset.map { Phoneme(sound: $0) } + tail))
        }
        let tenderly = word("TENDERLY", onset: [.T])
        let slenderly = word("SLENDERLY", onset: [.S, .L])
        #expect(tenderly.perfectRhyme(syllablesFromEnd: 3)?.description == "EH1-N-D-ER0-L-IY0")
        #expect(tenderly.perfectRhyme(syllablesFromEnd: 3) == slenderly.perfectRhyme(syllablesFromEnd: 3))
	}
}
