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
    /// The rhymes don't depend on the tags, so the line isn't tagged.
    func line(_ string: String) -> Line {
        Line(parts: [Part(speaker: 0, string: string)], string: string)
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

    /// "bell" and "tell" match from the stressed vowel onwards, even though their first consonants differ.
    @Test func testSingleRhymeIgnoresTheLeadingConsonants() {
        #expect(pair("Ring the bell.", "Do tell.").availableRhymes == [.single, .assonance, .consonance, .half])
    }

    /// "funny" and "money" match from the stressed penultimate vowel to the end.
    @Test func testDoubleRhyme() {
        let rhymes = pair("Very funny.", "No money.").availableRhymes
        #expect(rhymes == [.double, .syllabic, .assonance, .consonance, .half])
        #expect(rhymes.contains(.single) == false)
    }

    /// "almost" and "also" share a stressed penultimate syllable, but their final syllables differ.
    @Test func testDoubleRhymeNeedsTheFinalSyllableToMatch() {
        #expect(pair("We are almost.", "And also.").availableRhymes == [.assonance, .consonance, .alliteration])
    }

    /// "hospital" and "holiday" share a stressed antepenultimate syllable, but the syllables after it differ.
    /// The lexicon has no dactylic rhymes, so `WordTests` covers a matching pair.
    @Test func testDactylicRhymeNeedsTheFollowingSyllablesToMatch() {
        #expect(pair("Go to hospital.", "On holiday.").availableRhymes == [.assonance, .consonance, .alliteration])
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
