//
//  RhymeTypeTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Testing
@testable import ConnaughtSquare

/// The rhyme classifications are driven by the last word of each line, so these use words that are
/// in the lexicon. Update the expectations when rhyme identification changes.
struct RhymeTypeTests {
    func line(_ string: String) -> Line {
        Line(parts: [Part(speaker: 0, string: string)])
    }

    func pair(_ first: String, _ second: String) -> LinePair {
        LinePair(first: line(first), second: line(second))
    }

    @Test func testAllCases() {
        #expect(RhymeType.allCases.count == 13)
        #expect(RhymeType.allCases.prefix(3) == [.single, .double, .dactylic])
    }

    @Test(arguments: RhymeType.allCases)
    func testDescriptionIsRawValue(type: RhymeType) {
        #expect(type.description == type.rawValue)
    }

    /// "buy" and "bye" share every phoneme, so they match every implemented classification.
    @Test func testIdenticalPronunciations() {
        #expect(pair("I will buy.", "Say bye.").availableRhymes ==
                [.single, .syllabic, .assonance, .consonance, .half, .pararhyme, .alliteration])
    }

    /// "before" and "four" share a stressed final syllable but start differently.
    @Test func testSingleRhyme() {
        let rhymes = pair("Just before.", "All four.").availableRhymes
        #expect(rhymes == [.single, .syllabic, .assonance, .consonance, .half])
        #expect(rhymes.contains(.alliteration) == false)
        #expect(rhymes.contains(.pararhyme) == false)
    }

    /// "almost" and "also" share a stressed penultimate syllable.
    @Test func testDoubleRhyme() {
        let rhymes = pair("We are almost.", "And also.").availableRhymes
        #expect(rhymes == [.double, .assonance, .consonance, .alliteration])
        #expect(rhymes.contains(.single) == false)
    }

    /// "hospital" and "holiday" share a stressed antepenultimate syllable.
    @Test func testDactylicRhyme() {
        let rhymes = pair("Go to hospital.", "On holiday.").availableRhymes
        #expect(rhymes == [.dactylic, .assonance, .consonance, .alliteration])
        #expect(rhymes.contains(.single) == false)
        #expect(rhymes.contains(.double) == false)
    }

    @Test func testLinesThatDoNotRhyme() {
        #expect(pair("Here is the man.", "He is thirty.").availableRhymes.isEmpty)
    }

    /// A line is only classified when its last word has a pronunciation in the lexicon.
    @Test(arguments: RhymeType.allCases)
    func testWordsOutsideTheLexiconNeverRhyme(type: RhymeType) {
        #expect(type.linesRhyme(pair("A zzzzq.", "Another zzzzq.")) == false)
    }

    /// These classifications have not been implemented yet, so they never match.
    @Test(arguments: [RhymeType.imperfect, .weak, .semi, .forced])
    func testUnimplementedRhymeTypes(type: RhymeType) {
        #expect(type.linesRhyme(pair("I will buy.", "Say bye.")) == false)
    }

    @Test(arguments: RhymeType.allCases)
    func testALineRhymesWithItself(type: RhymeType) {
        let pair = pair("I will buy.", "I will buy.")
        let reversed = LinePair(first: pair.second, second: pair.first)
        #expect(type.linesRhyme(pair) == type.linesRhyme(reversed))
    }
}
