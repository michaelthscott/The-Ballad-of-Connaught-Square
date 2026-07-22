//
//  WeightedLinguisticTagTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 09/11/2023.
//

import Testing
import NaturalLanguage
@testable import ConnaughtSquare

struct WeightedLinguisticTagTests {

    @Test func testInit() {
        var tag = WeightedLinguisticTag(rawValue: .noun, weight: 123)
        #expect(tag == .noun(weight: 123))
        #expect(tag.weight == 123)
        tag.weight = 321
        #expect(tag.weight == 321)
    }

    @Test func testWeight() {
        let tag: WeightedLinguisticTag = .noun(weight: 123)
        #expect(tag.weight == 123)
    }

    @Test func testString() {
        let tag: WeightedLinguisticTag = .verb(weight: 123)
        #expect(tag.name == "Verb")
    }

    @Test func testDescription() {
        let tag: WeightedLinguisticTag = .adjective(weight: 123)
        #expect(tag.description == "Adjective(123)")
    }

    /*
     a == a is always true (Reflexivity)
     a == b implies b == a (Symmetry)
     a == b and b == c implies a == c (Transitivity)
     */

    @Test func testEquatable() {
        #expect(WeightedLinguisticTag.verb(weight: 1) == WeightedLinguisticTag.verb(weight: 1))
        #expect(WeightedLinguisticTag.verb(weight: 1) == WeightedLinguisticTag.verb(weight: 2) && WeightedLinguisticTag.verb(weight: 2) == WeightedLinguisticTag.verb(weight: 1))
        #expect(WeightedLinguisticTag.verb(weight: 1) == WeightedLinguisticTag.verb(weight: 2) && WeightedLinguisticTag.verb(weight: 2) == WeightedLinguisticTag.verb(weight: 3) && WeightedLinguisticTag.verb(weight: 1) == WeightedLinguisticTag.verb(weight: 3))
    }
    
    /*
     a < a is always false (Irreflexivity)
     a < b implies !(b < a) (Asymmetry)
     a < b and b < c implies a < c (Transitivity)
     */

    @Test func testComparable() {
        // Weight
        #expect(( WeightedLinguisticTag.verb(weight: 1) < WeightedLinguisticTag.verb(weight: 1) ) == false)
        
        #expect(
            WeightedLinguisticTag.verb(weight: 2) < WeightedLinguisticTag.verb(weight: 1) &&
            !(WeightedLinguisticTag.verb(weight: 1) < WeightedLinguisticTag.verb(weight: 2))
        )
        
        // Name
        #expect(
            WeightedLinguisticTag.adjective() < WeightedLinguisticTag.noun() &&
            WeightedLinguisticTag.noun() < WeightedLinguisticTag.verb() &&
            WeightedLinguisticTag.adjective() < WeightedLinguisticTag.verb()
        )
    }
    
    @Test func testCodable() throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let tag: WeightedLinguisticTag = .adjective(weight: 123)
        let data = try encoder.encode(tag)
        let decoder = PropertyListDecoder()
        var format = encoder.outputFormat
        let copy = try decoder.decode(WeightedLinguisticTag.self, from: data, format: &format)
        #expect(copy.name == tag.name)
        #expect(copy.weight == tag.weight)
    }

}
