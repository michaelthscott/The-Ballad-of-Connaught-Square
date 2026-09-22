//
//  SyllableSegmentTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Testing
@testable import ConnaughtSquare

/// Covers the three segments a syllable is built from: the onset, the nucleus and the coda.
struct SyllableSegmentTests {

    @Test func testOnset() {
        let onset = Onset(phonemes: [Phoneme(sound: .S), Phoneme(sound: .T)])
        #expect(onset.phonemesCount == 2)
        #expect(onset.description == "O[S, T]")
    }

    @Test func testEmptyOnset() {
        let onset = Onset(phonemes: [])
        #expect(onset.phonemesCount == 0)
        #expect(onset.description == "O[]")
    }

    @Test func testNucleus() {
        let nucleus = Nucleus(phoneme: Phoneme(sound: .AE, stress: .primaryStress))
        #expect(nucleus.phonemesCount == 1)
        #expect(nucleus.description == "N[AE1]")
    }

    @Test func testCoda() {
        let coda = Coda(phonemes: [Phoneme(sound: .N), Phoneme(sound: .T)])
        #expect(coda.phonemesCount == 2)
        #expect(coda.description == "C[N, T]")
    }

    @Test func testEmptyCoda() {
        let coda = Coda(phonemes: [])
        #expect(coda.phonemesCount == 0)
        #expect(coda.description == "C[]")
    }

    /// The segments combine into the syllable's own description without the segment markers.
    @Test func testSegmentsFormASyllable() {
        let syllable = Syllable(onset: Onset(phonemes: [Phoneme(sound: .M)]),
                                nucleus: Nucleus(phoneme: Phoneme(sound: .AE, stress: .primaryStress)),
                                coda: Coda(phonemes: [Phoneme(sound: .N)]))
        #expect(syllable.description == "M-AE1-N")
        #expect(syllable.ipa == "mæn")
    }
}
