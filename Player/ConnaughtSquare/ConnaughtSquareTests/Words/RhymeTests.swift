//
//  RhymeTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Testing
@testable import ConnaughtSquare

struct RhymeTests {
    
    @Test func testComparable() {
        let rhyme1 = Rhyme(phonemes: [Phoneme(sound: .AA, stress: .primaryStress), Phoneme(sound: .M)])
        let rhyme2 = Rhyme(phonemes: [Phoneme(sound: .AH, stress: .primaryStress), Phoneme(sound: .N)])
        #expect(rhyme1 < rhyme2)
    }
    
    @Test func testDescription() {
        #expect(Rhyme(phonemes: [Phoneme(sound: .AA, stress: .primaryStress), Phoneme(sound: .N)]).description == "AA1-N")
    }
    
}
