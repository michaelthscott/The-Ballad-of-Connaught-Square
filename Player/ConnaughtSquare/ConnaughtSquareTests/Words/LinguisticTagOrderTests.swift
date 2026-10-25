//
//  LinguisticTagOrderTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 10/11/2023.
//

import Testing
import NaturalLanguage
import SwiftUI
@testable import ConnaughtSquare

final class LinguisticTagOrderTests {
    var tags: LinguisticTagOrder!
    
    // [.noun, .noun, .verb]
    init() throws {
        tags = decodeAsset("TagsTest", from: Bundle(for: Self.self))
    }

    deinit {
        tags = nil
    }

    @Test func testInit() throws {
        #expect(tags.weight(of: .noun()) == 2)
        #expect(tags.weight(of: .verb()) == 1)
        #expect(tags.weight(of: .adjective()) == 0)
    }
    
    @Test func testIndexOf() {
        // TODO: This used to be index == 0 because the tags were rearranged to be in weight decending order.
        #expect(tags.index(of: .noun()) == 0)
    }

    @Test func testIndexOfAMissingTagLeavesTheOrderingUnchanged() {
        let order = LinguisticTagOrder(tags: [.noun(weight: 2)])
        #expect(order.index(of: .verb()) == nil)
        #expect(order.weight(of: .verb()) == 0)
        #expect(order.count == 1)
    }

    @Test func testWeightOf() {
        #expect(tags.weight(of: .noun()) == 2)
    }
    
    @Test func testCount() {
        #expect(tags.count == 17)
    }
    
    @Test func testSubscript() {
        #expect(tags[0] == .noun && tags[0].weight == 2)
        #expect(tags[1] == .verb && tags[1].weight == 1)
		tags[0] = .noun(weight: 3)
        #expect(tags[0] == .noun && tags[0].weight == 3)
        #expect(tags[1] == .verb && tags[1].weight == 1)
		tags[10] = .noun(weight: 4)
        #expect(tags[0] == .verb && tags[0].weight == 1)
        #expect(tags[10] == .noun && tags[10].weight == 4)
		tags[16] = .verb(weight: 5)
        #expect(tags[9] == .noun && tags[9].weight == 4)
        #expect(tags[16] == .verb && tags[16].weight == 5)
    }
    
    @Test func testOrderedByWeight() {
        let ordered = tags.tagsOrderedByWeight().filter { $0.weight > 0 }
        #expect(ordered == [.noun(), .verb()])
    }

    @Test func testCodable() throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(tags)
        let decoder = PropertyListDecoder()
        var format = encoder.outputFormat
        let copy = try decoder.decode(LinguisticTagOrder.self, from: data, format: &format)
        #expect(copy == tags)
    }

    @Test func testAreOrdered() {
        #expect(tags.areOrdered([], []) == false)
        #expect(tags.areOrdered([], [.noun]) == false)
        #expect(tags.areOrdered([.noun], []))
        #expect(tags.areOrdered([.noun], [.noun]) == false)
        #expect(tags.areOrdered([.noun], [.verb]))
        #expect(tags.areOrdered([.verb], [.noun]) == false)
    }

    /// The first position where the tags differ decides the order, so it never goes both ways.
    @Test func testAreOrderedIsAsymmetric() {
        #expect(tags.areOrdered([.noun, .verb], [.verb, .noun]))
        #expect(tags.areOrdered([.verb, .noun], [.noun, .verb]) == false)
        #expect(tags.areOrdered([.noun, .verb], [.noun, .noun]) == false)
        #expect(tags.areOrdered([.noun, .noun], [.noun, .verb]))
        // When one starts with the other, the longer one comes first.
        #expect(tags.areOrdered([.noun, .verb], [.noun]))
        #expect(tags.areOrdered([.noun], [.noun, .verb]) == false)
    }
	
    @Test func testMove() {
        #expect(tags.index(of: .noun()) == 0)
		tags.move(fromOffsets: [0], toOffset: 2)
        #expect(tags.index(of: .noun()) == 1)
	}

}
