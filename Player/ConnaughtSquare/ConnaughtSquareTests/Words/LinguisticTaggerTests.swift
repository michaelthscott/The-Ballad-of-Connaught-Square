//
//  LinguisticTaggerTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 12/11/2023.
//

import Testing
@testable import ConnaughtSquare

struct LinguisticTaggerTests {

    @Test(.enabled(if: LinguisticTagger().isTagSchemeAvailable)) func testLinguisticTagsArray() throws {
        let tags = try LinguisticTagger().linguisticTagsArray(string: "Man eats dog")
        #expect(tags[0] == .noun)
        #expect(tags[1] == .verb)
        #expect(tags[2] == .noun)
    }

    @Test(.disabled(if: LinguisticTagger().isTagSchemeAvailable)) func testLinguisticTagsArrayThrowsWhenTheTagSchemeIsUnavailable() {
        #expect(throws: LinguisticTaggerError.self) {
            try LinguisticTagger().linguisticTagsArray(string: "Man eats dog")
        }
    }

}
