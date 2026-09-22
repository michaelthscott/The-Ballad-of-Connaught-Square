//
//  TagSortOrderTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Foundation
import Testing
@testable import ConnaughtSquare

struct TagSortOrderTests {

    @Test func testAllCases() {
        #expect(TagSortOrder.allCases == [.ascending, .descending, .invert, .random, .choose])
    }

    @Test(arguments: TagSortOrder.allCases)
    func testDescriptionIsRawValue(order: TagSortOrder) {
        #expect(order.description == order.rawValue)
    }

    @Test(arguments: TagSortOrder.allCases)
    func testIdentifiable(order: TagSortOrder) {
        #expect(order.id == order)
    }

    /// The order is persisted in the settings, so it has to survive a round trip.
    @Test(arguments: TagSortOrder.allCases)
    func testCodable(order: TagSortOrder) throws {
        let data = try PropertyListEncoder().encode([order])
        let copy = try PropertyListDecoder().decode([TagSortOrder].self, from: data)
        #expect(copy == [order])
    }

    @Test func testDecodingAnUnknownOrderFails() throws {
        let data = try PropertyListEncoder().encode(["Sideways"])
        #expect(throws: DecodingError.self) {
            try PropertyListDecoder().decode([TagSortOrder].self, from: data)
        }
    }
}
