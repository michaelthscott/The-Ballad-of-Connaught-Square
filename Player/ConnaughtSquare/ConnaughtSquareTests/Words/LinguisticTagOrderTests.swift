//
//  LinguisticTagOrderTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 10/11/2023.
//

import Testing
import NaturalLanguage
import SwiftUI
import Observation
import Synchronization
@testable import ConnaughtSquare

final class LinguisticTagOrderTests {
    var tags: LinguisticTagOrder!
    
    // [.noun, .noun, .verb], with every other tag at weight 0, after them in order of name.
    init() {
        let others = WeightedLinguisticTag.allCases.filter { $0 != .noun() && $0 != .verb() }
        tags = LinguisticTagOrder(tags: [.noun(weight: 2), .verb(weight: 1)] + others)
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
		// Moving a tag shifts the others, and keeps each tag exactly once with its weight.
		tags.move(fromOffsets: [0], toOffset: 11)
        #expect(tags[0] == .verb && tags[0].weight == 1)
        #expect(tags[10] == .noun && tags[10].weight == 2)
		tags.move(fromOffsets: [0], toOffset: 17)
        #expect(tags[9] == .noun && tags[9].weight == 2)
        #expect(tags[16] == .verb && tags[16].weight == 1)
        #expect(Set(tags.map(\.name)).count == 17)
    }

    /// `WeightedSet` is a class, so rearranging it in place must still tell observers, or the tag list wouldn't refresh.
    @Test(arguments: [TagSortOrder.ascending, .descending, .invert, .random])
    func testReorderingNotifiesObservers(order: TagSortOrder) {
        let tags = LinguisticTagOrder(tags: [.noun(weight: 3), .verb(weight: 2), .adverb(weight: 1)])
        let notified = Mutex(false)
        withObservationTracking {
            _ = tags.ordering
        } onChange: {
            notified.withLock { $0 = true }
        }
        tags.orderTags(with: order)
        #expect(notified.withLock { $0 })
    }

    @Test func testMoveNotifiesObservers() {
        let notified = Mutex(false)
        withObservationTracking {
            _ = tags.ordering
        } onChange: {
            notified.withLock { $0 = true }
        }
        tags.move(fromOffsets: [0], toOffset: 2)
        #expect(notified.withLock { $0 })
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

    /// Counts each tag across the lines, heaviest first, leaving out tags that don't appear.
    @Test func testInitFromLines() {
        let lines = [
            Line(parts: [Part(speaker: 0, string: "Dogs chase dogs")], string: "Dogs chase dogs", tags: [.noun, .verb, .noun]),
            Line(parts: [Part(speaker: 0, string: "Run home")], string: "Run home", tags: [.verb, .noun]),
        ]
        let order = LinguisticTagOrder(lines: lines)
        #expect(order.map { "\($0.name)=\($0.weight)" } == ["Noun=3", "Verb=2"])
        #expect(order.index(of: .adjective()) == nil)
        #expect(LinguisticTagOrder(lines: []).isEmpty)
    }

    /// Pins the ballad's tags, weights and order, heaviest first, as counted from its lines, so that refactoring `WeightedSet` can't change them unnoticed.
    /// The weights are those the Tags asset held before the order was counted from the lines.
    @Test func testBalladTagOrderIsUnchanged() {
        let ballad = Ballad()
        let expected = ["Verb=1983", "Pronoun=1270", "Noun=1257", "Adverb=841", "Determiner=745", "Preposition=650", "Interjection=450", "Adjective=400", "Number=244", "Particle=223", "Conjunction=193", "PersonalName=50", "PlaceName=33", "OrganizationName=10", "OtherWord=4"]
        #expect(ballad.tags.map { "\($0.name)=\($0.weight)" } == expected)
    }

}
