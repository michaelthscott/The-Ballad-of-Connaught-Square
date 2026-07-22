//
//  SyllableTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Foundation
import Testing
@testable import ConnaughtSquare

final class SyllableTests {
	var lexicon: Lexicon!
	
	init() {
		lexicon = Lexicon(name: "Lexicon", bundle: Bundle(for: Lexicon.self))
	}
	
	deinit {
		lexicon = nil
	}
	
    @Test func testInit() {
        #expect(lexicon.word("MAN")?.finalSyllable?.ipa == "mæn")
    }

    @Test func testDescription() {
        #expect(lexicon.word("MAN")?.finalSyllable?.description == "M-AE1-N")
    }
    
    @Test func testRhyme() {
        #expect(lexicon.word("MAN")?.finalSyllable?.rhyme == Rhyme(phonemes: [Phoneme(sound: .AE, stress: .primaryStress), Phoneme(sound: .N)]))
    }
	
    @Test func testIsStressed() {
        #expect(lexicon.word("MAN")?.finalSyllable?.isStressed ?? false)
	}
}
