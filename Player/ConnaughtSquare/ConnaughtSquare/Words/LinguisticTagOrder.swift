//
//  LinguisticTagOrder.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 10/11/2023.
//

import Foundation
import NaturalLanguage
import SwiftUI

/// Ordered linguistic tags.
@Observable final class LinguisticTagOrder {
    var ordering: WeightedSet<WeightedLinguisticTag>
    
    init(tags: [WeightedLinguisticTag]) {
        ordering = .init()
		// We are assuming that the tags have at least weight 1.
        for tag in tags {
            ordering[ordering.position(of: tag)].weight = tag.weight
        }
        ordering.sort()
    }
    
    /// The position of the tag in the ordering.
    /// - Parameter tag: The specified tag.
    /// - Returns: The position of the tag.
    func index(of tag: WeightedLinguisticTag) -> Int {
        ordering.position(of: tag)
    }

    /// The number of words that map to the tag.
    /// - Parameter tag: The tag.
    /// - Returns: The weight of the tag.
    func weight(of tag: WeightedLinguisticTag) -> Int {
        ordering[ordering.position(of: tag)].weight
    }

    var count: Int {
        ordering.count
    }
    
    func tagsOrderedByWeight() -> [WeightedLinguisticTag] {
        ordering.elements.sorted { lhs, rhs in
            lhs.weight > rhs.weight
        }
    }
}

extension LinguisticTagOrder: Sequence {
	typealias Element = WeightedLinguisticTag
	
	func makeIterator() -> IndexingIterator<Array<WeightedLinguisticTag>> {
		ordering.elements.makeIterator()
	}
}

extension LinguisticTagOrder: Collection {
	typealias Index = Array<WeightedLinguisticTag>.Index
	
	var startIndex: LinguisticTagOrder.Index {
		ordering.elements.startIndex
	}

	var endIndex: LinguisticTagOrder.Index {
		ordering.elements.endIndex
	}

	func index(after i: LinguisticTagOrder.Index) -> LinguisticTagOrder.Index {
		ordering.elements.index(after: i)
	}
}

extension LinguisticTagOrder: MutableCollection {
	subscript(position: Array<WeightedLinguisticTag>.Index) -> WeightedLinguisticTag {
		get {
			ordering[position]
		}
		set(newValue) {
			ordering[position] = newValue
		}
	}
}

extension LinguisticTagOrder: RandomAccessCollection {
	
}

extension LinguisticTagOrder: Equatable {
	static func == (lhs: LinguisticTagOrder, rhs: LinguisticTagOrder) -> Bool {
		lhs.ordering.description == rhs.ordering.description
	}
}

// MARK: - Codable
extension LinguisticTagOrder: Codable {
    enum CodingKeys: String, CodingKey {
        case ordering
    }
    
    /// Encodes the tag order.
    /// - Parameter encoder: The encoder.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ordering.elements, forKey: .ordering)
    }
    
    /// Decodes the ballad.
    /// - Parameter decoder: The decoder.
	convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tags = try container.decode([WeightedLinguisticTag].self, forKey: .ordering)
        self.init(tags: tags)
    }
}

extension LinguisticTagOrder {
	/// Compares two tags by their position in the ordering.
    /// - Parameters:
    ///   - lhs: Left-hand tag.
    ///   - rhs: Right-hand tag.
    /// - Returns: Whether the tags are ordered.
    func areOrdered(_ lhs: LinguisticTag, _ rhs: LinguisticTag) -> Bool {
		index(of: WeightedLinguisticTag(rawValue: lhs)) < index(of: WeightedLinguisticTag(rawValue: rhs))
    }
    
    /// Compares two arrays of linguistic tags.
    /// Note that two empty arrays are not ordered, and that an empty array is ordered last.
    /// - Parameters:
    ///   - lhs: Left-hand tags.
    ///   - rhs: Right-hand tags.
    /// - Returns: How the tags compare..
    func areOrdered(_ lhs: [LinguisticTag], _ rhs: [LinguisticTag]) -> Bool {
        if lhs.count == 0 && rhs.count == 0 {
            return false
        }
        // TODO: I need to check this logic.
		// Note that min() is also an instance method when Element conforms to Comparable.
		let count = Swift.min(lhs.count, rhs.count)
        for i in 0..<count {
            if areOrdered(lhs[i], rhs[i]) {
                return true
            }
        }
        if lhs.count == rhs.count {
            for i in 0..<count {
                if areOrdered(lhs[i], rhs[i]) {
                    return true
                }
            }
            return false
        }
        return lhs.count > rhs.count
    }
    
    /// Orders the tags in the specified order.
    /// - Parameter order: An order.
    func orderTags(with order: TagSortOrder) {
        switch order {
        case .ascending:
            let tags = Array(tagsOrderedByWeight().reversed())
            for position in tags.indices {
                ordering.move(fromOffsets: IndexSet([index(of: tags[position])]), toOffset: position)
            }
        case .descending:
            let tags = tagsOrderedByWeight()
            for position in tags.indices {
                ordering.move(fromOffsets: IndexSet([index(of: tags[position])]), toOffset: position)
            }
        case .invert:
            ordering.reverse()
        case .random:
            ordering.shuffle()
        case .choose:
            break
        }
    }
}

extension LinguisticTagOrder: CustomStringConvertible {
	var description: String {
		// We use this to check whether the order of the tags has changed.
		ordering.description
	}
}

