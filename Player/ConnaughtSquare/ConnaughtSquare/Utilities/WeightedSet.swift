//
//  WeightedSet.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 12/12/2023.
//

// TODO: What do we need Element: Codable for?
// TODO: What do we need Element: Hashable for?

import Foundation
import SwiftUI

typealias WeightedSetElement = Weighted & Comparable & Hashable & Codable

struct WeightedSet<Element: WeightedSetElement>: RandomAccessCollection {
    private(set) var elements: [Element]
	
	/// The empty set.
    init() {
		elements = []
    }
	
	/// Initialise the set with the specified elements.
	/// Note that weights will be summed for identical elements.
	/// - Parameter elements: Initial elements for the set.
	init(_ elements: [Element]) {
		self.init()
		for element in elements {
			addWeight(element.weight, to: element)
		}
		self.elements.sort()
	}
	
	/// The elements which have a non-zero weight.
    var weightedElements: [Element] {
        elements.filter { $0.weight > 0 }
    }

	/// Selects an element at random, with a probability proportional to its weight.
	///
	/// Elements with a weight of zero or less are never selected.
	/// - Parameter generator: The random number generator to use.
	/// - Returns: The element, or `nil` if no element has a positive weight.
	func weightedRandomElement<T: RandomNumberGenerator>(using generator: inout T) -> Element? {
		let candidates = weightedElements
		let totalWeight = candidates.reduce(0) { $0 + $1.weight }
		guard totalWeight > 0 else { return nil }
		// Pick a point in the total weight, then find the element whose share of the total contains it.
		var remaining = Int.random(in: 0..<totalWeight, using: &generator)
		for candidate in candidates {
			if remaining < candidate.weight {
				return candidate
			}
			remaining -= candidate.weight
		}
		return nil
	}

	/// Selects an element at random, with a probability proportional to its weight.
	///
	/// Elements with a weight of zero or less are never selected.
	/// - Returns: The element, or `nil` if no element has a positive weight.
	func weightedRandomElement() -> Element? {
		var generator = SystemRandomNumberGenerator()
		return weightedRandomElement(using: &generator)
	}
	
	/// Whether the set has no element with a positive weight, matching `contains(_:)`.
	///
	/// Zero-weight slots don't count, so a set can be empty while `count` is not zero.
    var isEmpty: Bool {
        !elements.contains { $0.weight > 0 }
    }
    
    /// The start index.
    var startIndex: Int {
        elements.startIndex
    }
    
    /// The end index.
    var endIndex: Int {
        elements.endIndex
    }
    
    /// The weight of an element. This doesn't change the set.
    /// - Parameter element: The element.
    /// - Returns: The associated weight, or zero if the set doesn't hold the element.
	func weight(of element: Element) -> Int {
        elements.firstIndex(of: element).map { elements[$0].weight } ?? 0
    }

    /// The index of an element, adding a zero-weight slot for it at the end if the set doesn't hold it.
    /// To look an element up without changing the set, use `firstIndex(of:)`, `weight(of:)` or `contains(_:)`.
    private mutating func slot(for element: Element) -> Int {
        if let index = elements.firstIndex(of: element) {
            return index
        }
		var copy = element
		copy.weight = 0
		elements.append(copy)
		return elements.endIndex - 1
    }

    /// Sets the weight of an element, adding the element to the end of the set if it doesn't hold it.
    /// - Parameters:
    ///   - weight: The new weight.
    ///   - element: The element. Its own weight is ignored.
    mutating func setWeight(_ weight: Int, of element: Element) {
        elements[slot(for: element)].weight = weight
    }

    /// Adds to the weight of an element, adding the element to the end of the set if it doesn't hold it.
    /// - Parameters:
    ///   - weight: The weight to add.
    ///   - element: The element. Its own weight is ignored.
    mutating func addWeight(_ weight: Int, to element: Element) {
        elements[slot(for: element)].weight += weight
    }

    // The set isn't a MutableCollection: these rearrange the elements without being able to create duplicates.

    /// Moves the elements at the specified offsets to the specified destination offset.
    mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        elements.move(fromOffsets: source, toOffset: destination)
    }

    /// Reverses the order of the elements.
    mutating func reverse() {
        elements.reverse()
    }

    /// Shuffles the elements.
    mutating func shuffle() {
        elements.shuffle()
    }

    /// Shuffles the elements, using the specified random number generator.
    mutating func shuffle<T: RandomNumberGenerator>(using generator: inout T) {
        elements.shuffle(using: &generator)
    }

    /// Sorts the elements with the specified ordering.
    mutating func sort(by areInIncreasingOrder: (Element, Element) -> Bool) {
        elements.sort(by: areInIncreasingOrder)
    }

    /// The element at the specified position.
    subscript(position: Int) -> Element {
        elements[position]
    }

	/// The elements in the specified range.
	subscript(bounds: Range<Int>) -> ArraySlice<Element> {
		elements[bounds]
	}
}

// MARK: - Equatable
extension WeightedSet: Equatable {
    /// Two sets are equal when they hold the same elements with the same weights.
    /// The order of the elements and any zero-weight slots are ignored.
    static func == (lhs: WeightedSet, rhs: WeightedSet) -> Bool {
        let lhsElements = lhs.weightedElements.sorted()
        let rhsElements = rhs.weightedElements.sorted()
        return lhsElements.count == rhsElements.count
            && zip(lhsElements, rhsElements).allSatisfy { $0 == $1 && $0.weight == $1.weight }
    }
}

// MARK: - Codable
extension WeightedSet: Codable {
    enum CodingKeys: String, CodingKey {
        case elements
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(elements, forKey: .elements)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let elements = try container.decode([Element].self, forKey: .elements)
		self.init(elements)
    }
}

// MARK - Hashable
extension WeightedSet: Hashable {
    /// Hashes each weighted element with its weight, in order, to match `==`.
    func hash(into hasher: inout Hasher) {
        for element in weightedElements.sorted() {
            hasher.combine(element)
            hasher.combine(element.weight)
        }
    }
}

// MARK: - Set operations

// These follow SetAlgebra's names, but the set doesn't conform to it: adding weights breaks its laws,
// so that, for example, x.union(x) doubles every weight rather than equalling x.
extension WeightedSet {
	func contains(_ element: Element) -> Bool {
        weight(of: element) > 0
    }

	func union(_ other: WeightedSet) -> WeightedSet {
        var union = WeightedSet(elements)
        for element in other.elements {
			union.addWeight(element.weight, to: element)
        }
        return union
    }
    
	func intersection(_ other: WeightedSet) -> WeightedSet {
        var intersection = WeightedSet()
        for element in other.elements {
            if contains(element) && other.contains(element) {
				let weight = weight(of: element) + other.weight(of: element)
                intersection.setWeight(weight, of: element)
            }
        }
        return intersection
    }
    
    func symmetricDifference(_ other: WeightedSet) -> WeightedSet {
        var symmetricDifference = WeightedSet()
        for element in elements {
            if !other.contains(element) {
                symmetricDifference.setWeight(element.weight, of: element)
            }
        }
        for element in other.elements {
            if !contains(element) {
                symmetricDifference.setWeight(element.weight, of: element)
            }
        }
        return symmetricDifference
    }
    
    /// Adds the new member's weight to the element's weight.
    /// - Parameter newMember: The element, with the weight to add.
    /// - Returns: Whether the set didn't contain the element before but does now, and the element as it is after the insertion.
    @discardableResult
    mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let alreadyContains = contains(newMember)
        let index = slot(for: newMember)
        elements[index].weight += newMember.weight
        return (!alreadyContains && contains(newMember), elements[index])
    }

    /// Takes the member's weight away from the element's weight, stopping at zero.
    /// A member with no positive weight, such as `Element(rawValue:)`, takes away all of the element's weight.
    /// - Parameter member: The element, with the weight to take away.
    /// - Returns: The element as it was before the removal, or `nil` if the set didn't contain it.
    @discardableResult
    mutating func remove(_ member: Element) -> Element? {
        guard let index = elements.firstIndex(of: member), elements[index].weight > 0 else { return nil }
        let removed = elements[index]
        let reduction = member.weight > 0 ? member.weight : removed.weight
        elements[index].weight = Swift.max(removed.weight - reduction, 0)
        return removed
    }

    /// Replaces the element's weight with the new member's weight.
    /// - Parameter newMember: The element, with its new weight.
    /// - Returns: The element as it was before the update, or `nil` if the set didn't contain it.
    @discardableResult
    mutating func update(with newMember: Element) -> Element? {
        let previous = elements.firstIndex(of: newMember).map { elements[$0] }
        setWeight(newMember.weight, of: newMember)
        return previous.flatMap { $0.weight > 0 ? $0 : nil }
    }
    
	mutating func formUnion(_ other: WeightedSet) {
		elements = union(other).elements
    }
    
	mutating func formIntersection(_ other: WeightedSet) {
		elements = intersection(other).elements
    }

	mutating func formSymmetricDifference(_ other: WeightedSet) {
		elements = symmetricDifference(other).elements
    }
    
	mutating func subtract(_ other: WeightedSet) {
		elements = subtracting(other).elements
    }
    
	func subtracting(_ other: WeightedSet) -> WeightedSet {
        var copy = self
        for element in other.elements {
            guard let index = copy.elements.firstIndex(of: element) else { continue }
            copy.elements[index].weight = Swift.max(copy.elements[index].weight - element.weight, 0)
        }
        return copy
    }
    
    // Returns a Boolean value that indicates whether the set has no members in common with the given set.
	func isDisjoint(with other: WeightedSet) -> Bool {
        for element in weightedElements {
            if other.contains(element) {
                return false
            }
        }
        return true
    }
    
    /// Whether every weighted element of this set has at least as much weight in the other set.
    func isSubset(of other: WeightedSet) -> Bool {
        weightedElements.allSatisfy { other.weight(of: $0) >= $0.weight }
    }

    /// Whether every weighted element of the other set has at least as much weight in this set.
    func isSuperset(of other: WeightedSet) -> Bool {
        other.isSubset(of: self)
    }

    /// Whether this set is a subset of the other set but isn't equal to it.
    func isStrictSubset(of other: WeightedSet) -> Bool {
        isSubset(of: other) && self != other
    }

    /// Whether this set is a superset of the other set but isn't equal to it.
    func isStrictSuperset(of other: WeightedSet) -> Bool {
        other.isStrictSubset(of: self)
    }

}

// MARK: - ExpressibleByArrayLiteral
extension WeightedSet: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = Element
	init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(elements)
    }
}

// MARK: - CustomStringConvertible
extension WeightedSet: CustomStringConvertible {
    var description: String {
        "WeightedSet(\(elements))"
    }
}

// MARK: - Element: SafeRawRepresentable
extension WeightedSet where Element: SafeRawRepresentable {
	func weight(of rawValue: Element.RawValue) -> Int {
		weight(of: Element(rawValue: rawValue))
	}

	func contains(rawValue: Element.RawValue) -> Bool {
		contains(Element(rawValue: rawValue))
	}
}
