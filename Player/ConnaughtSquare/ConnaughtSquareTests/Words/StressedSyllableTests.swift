//
//  StressedSyllableTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Testing
@testable import ConnaughtSquare

struct StressedSyllableTests {
    /// The syllable of "man".
    let man = Syllable(onset: Onset(phonemes: [Phoneme(sound: .M)]),
                       nucleus: Nucleus(phoneme: Phoneme(sound: .AE, stress: .primaryStress)),
                       coda: Coda(phonemes: [Phoneme(sound: .N)]))
    /// The syllable of "bee".
    let bee = Syllable(onset: Onset(phonemes: [Phoneme(sound: .B)]),
                       nucleus: Nucleus(phoneme: Phoneme(sound: .IY, stress: .primaryStress)))

    @Test func testDescriptionIsTheSyllableDescription() {
        #expect(StressedSyllable.final(man).description == "M-AE1-N")
        #expect(StressedSyllable.penultimate(man).description == "M-AE1-N")
        #expect(StressedSyllable.antepenultimate(man).description == "M-AE1-N")
    }

    @Test func testEquatable() {
        #expect(StressedSyllable.final(man) == .final(man))
        #expect(StressedSyllable.final(man) != .final(bee))
    }

    /// Equality compares the syllables alone, so the same syllable in two positions is equal.
    @Test func testPositionIsIgnoredByEquality() {
        #expect(StressedSyllable.final(man) == .penultimate(man))
        #expect(StressedSyllable.penultimate(man) == .antepenultimate(man))
    }

    /// Hashing follows the same rule, so positions of one syllable collapse to a single member.
    @Test func testHashable() {
        let syllables: Set<StressedSyllable> = [.final(man), .penultimate(man), .final(bee)]
        #expect(syllables.count == 2)
        #expect(syllables.contains(.antepenultimate(man)))
    }
}
