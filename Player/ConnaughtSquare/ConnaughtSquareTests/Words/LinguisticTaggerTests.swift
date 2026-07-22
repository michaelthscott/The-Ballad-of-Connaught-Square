//
//  LinguisticTaggerTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 12/11/2023.
//

import Testing
@testable import ConnaughtSquare

struct LinguisticTaggerTests {

    @Test func testLinguisticTagsArray() throws {
        let tags = LinguisticTagger().linguisticTagsArray(string: "Man eats dog")
        #expect(tags[0] == .noun)
        #expect(tags[1] == .verb)
        #expect(tags[2] == .noun)
    }

}
