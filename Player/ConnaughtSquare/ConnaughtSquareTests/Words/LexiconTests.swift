//
//  LexiconTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Foundation
import Testing
@testable import ConnaughtSquare

final class LexiconTests {
    var lexicon: Lexicon!
    
    init() {
        lexicon = Lexicon(name: "LexiconTest", bundle: Bundle(for: Self.self))
    }
    
    deinit {
        lexicon = nil
    }
    
    @Test func testInit() {
        #expect(lexicon.word("bell") != nil)
    }

    // [B, EH1, L]
    // [B, ER1, N, IY0]
    // [B, IH0, M, OW1, N, IH0, NG]

    @Test func testWord() {
        let fixture = ["bell": 3, "Bernie": 4, "bemoaning": 7]
        for string in fixture.keys {
            if let word = Lexicon.shared.word(string) {
                #expect(word.string == string.uppercased())
                #expect(word.pronunciation.phonemes.count == fixture[string]!)
            } else {
                Issue.record("Failed to find \(string)")
            }
        }
    }
    
    @Test func testLegalOnsets() {
        // [[B]]
        #expect(lexicon.legalOnsets.count == 1)
    }
    
    @Test func testWords() {
        #expect(lexicon.words.count == 3)
	}
	
    @Test(.enabled(if: Lexicon.shared.word("BELL") == nil)) func testWordsRhymingWith() throws {
        let word = Lexicon.shared.word("BELL")!
		// [HELL, HOTEL, SMELL, SPELL, TELL, THEY'LL, WELL]
        #expect(Lexicon.shared.wordsRhyming(with: word) == [
			Lexicon.shared.word("HELL"),
			Lexicon.shared.word("HOTEL"),
			Lexicon.shared.word("SMELL"),
			Lexicon.shared.word("SPELL"),
			Lexicon.shared.word("TELL"),
			Lexicon.shared.word("THEY'LL"),
			Lexicon.shared.word("WELL")])
	}
}
