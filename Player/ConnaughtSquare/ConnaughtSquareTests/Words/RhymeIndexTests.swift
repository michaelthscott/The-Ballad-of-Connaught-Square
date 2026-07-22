//
//  RhymeIndexTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Testing
@testable import ConnaughtSquare

struct RhymeIndexTests {
    
    @Test func testIsUnused() {
        let rhymeIndex = RhymeIndex(rhyme: Rhyme(phonemes: [Phoneme(sound: .AA, stress: .primaryStress)]), index: 123)
        #expect(rhymeIndex.isUnused)
    }
    
    @Test func testDescription() {
        let rhymeIndex = RhymeIndex(rhyme: Rhyme(phonemes: [Phoneme(sound: .AA, stress: .primaryStress)]), index: 123)
        #expect(rhymeIndex.description == "(123, AA1, unused)")
    }
    
}
