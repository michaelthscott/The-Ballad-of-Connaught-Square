//
//  LinguisticTagTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Foundation
import NaturalLanguage
import Testing
@testable import ConnaughtSquare

struct LinguisticTagTests {

    @Test func testAllCases() {
        #expect(LinguisticTag.allCases.count == 17)
    }

    @Test(arguments: LinguisticTag.allCases)
    func testRawValueRoundTrip(tag: LinguisticTag) {
        #expect(LinguisticTag(rawValue: tag.rawValue) == tag)
    }

    @Test func testName() {
        #expect(LinguisticTag.noun.name == "Noun")
        #expect(LinguisticTag.personalName.name == "PersonalName")
    }

    @Test(arguments: LinguisticTag.allCases)
    func testDescriptionIsName(tag: LinguisticTag) {
        #expect(tag.description == tag.name)
    }

    /// `NLTag` is not an enum, so any tag the tagger produces that is not wrapped becomes a plain word.
    @Test func testUnknownTagIsOtherWord() {
        #expect(LinguisticTag(rawValue: NLTag("Gibberish")) == .otherWord)
        #expect(LinguisticTag(rawValue: .punctuation) == .otherWord)
    }

    /// Tags are ordered by the name of the underlying `NLTag`.
    @Test func testComparable() {
        #expect(LinguisticTag.adjective < LinguisticTag.noun)
        #expect(LinguisticTag.noun < LinguisticTag.verb)
        #expect((LinguisticTag.noun < LinguisticTag.noun) == false)
    }

    @Test(arguments: LinguisticTag.allCases)
    func testCodable(tag: LinguisticTag) throws {
        let data = try PropertyListEncoder().encode([tag])
        let copy = try PropertyListDecoder().decode([LinguisticTag].self, from: data)
        #expect(copy == [tag])
    }

    /// An archived tag that is no longer recognised decodes as a plain word rather than failing.
    @Test func testDecodingAnUnknownName() throws {
        let data = try PropertyListEncoder().encode([["name": "Gibberish"]])
        let copy = try PropertyListDecoder().decode([LinguisticTag].self, from: data)
        #expect(copy == [.otherWord])
    }
}
