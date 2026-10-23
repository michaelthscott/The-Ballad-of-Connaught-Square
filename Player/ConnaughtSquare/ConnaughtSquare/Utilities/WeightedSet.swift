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
typealias WeightedSetCollection = RandomAccessCollection & MutableCollection

final class WeightedSet<Element: WeightedSetElement>: WeightedSetCollection {
    private(set) var elements: [Element]
	
	/// The empty set.
    init() {
		elements = []
    }
	
	/// Initialise the set with the specified elements.
	/// Note that weights will be summed for identical elements.
	/// - Parameter elements: Initial elements for the set.
	convenience init(_ elements: [Element]) {
		self.init()
		for element in elements {
			// This will create an umweighted element if needed.
			let index = position(of: element)
			self.elements[index].weight += element.weight
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
	
	/// Whether the set is empty.
    var isEmpty: Bool {
        count == 0
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
        existingPosition(of: element).map { elements[$0].weight } ?? 0
    }

    /// The index of an element the set already holds. Unlike `position(of:)`, this doesn't change the set.
    /// - Parameter element: The element.
    /// - Returns: The index, or `nil` if the set doesn't hold the element.
	func existingPosition(of element: Element) -> Int? {
        elements.firstIndex(of: element)
    }

    /// The index of a specified element, adding an unweighted slot for it if the set doesn't hold it.
    ///
    /// Use this when assigning a weight. To look an element up without changing the set, use
    /// `existingPosition(of:)`, `weight(of:)` or `contains(_:)`.
    /// - Parameter element: The element.
    /// - Returns: The index.
	func position(of element: Element) -> Int {
        if let index = elements.firstIndex(of: element) {
            return index
        }
		// This just creates an unweighted slot for the element.
		var copy = element
		copy.weight = 0
		elements.append(copy)
		return position(of: element)
    }

	/*
	 An index is the position of an element. Offsets are the start and end of an element. The start offset is the index. The end offset is the index + 1.
	 1) If the element does not move then just update its value.
	 2) If the element is moved to somewhere towards the start of the array then the offset is same as the new index.
	 3) If the element is moved to somewhere towards the end of the array then the offset is same as the new index + 1.
	 */
	
    /// Used to access an element.
    /// Note that assigning a different element will cause the elements to be moved.
    subscript(position: Int) -> Element {
        get {
            elements[position]
        }
		set(newValue) {
			let previousPosition = self.position(of: newValue)
            if previousPosition != position {
				var offset: Int
				switch position {
				case startIndex:
					offset = 0
				case startIndex..<previousPosition:
					offset = position
				default:
					offset = position + 1
				}
				elements.move(fromOffsets: [previousPosition], toOffset: offset)
			}
			elements[position] = newValue
        }
    }
    
	/// Used to access a range of elements.
	/// Note that assigning different elements will cause the elements to be moved.
	subscript(bounds: Range<Int>) -> ArraySlice<Element> {
		get {
			elements[bounds]
		}
		set(newValue) {
			for (position, value) in zip(bounds, newValue) {
				let previousPosition = self.position(of: value)
				if previousPosition != position {
					elements.move(fromOffsets: [previousPosition], toOffset: position)
				}
				elements[position] = value
			}
		}
	}
}

// MARK: - Comparable
extension WeightedSet: Comparable {
    static func < (lhs: WeightedSet<Element>, rhs: WeightedSet<Element>) -> Bool {
        for (lhsElement, rhsElement) in zip(lhs.weightedElements.sorted(), rhs.weightedElements.sorted()) {
            if lhsElement >= rhsElement {
                return false
            }
        }
        return true
    }
}

// MARK: - Equatable
extension WeightedSet: Equatable {
    static func == (lhs: WeightedSet, rhs: WeightedSet) -> Bool {
        return lhs.weightedElements.sorted() == rhs.weightedElements.sorted()
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
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let elements = try container.decode([Element].self, forKey: .elements)
		self.init(elements)
    }
}

// MARK - Hashable
extension WeightedSet: Hashable {
    func hash(into hasher: inout Hasher) {
        for element in weightedElements.sorted() {
            hasher.combine(element)
        }
    }
}

// MARK: - SetAlgebra
extension WeightedSet: SetAlgebra {
	func contains(_ element: Element) -> Bool {
        weight(of: element) > 0
    }

	func union(_ other: WeightedSet) -> WeightedSet {
        let union = WeightedSet(elements)
        for element in other.elements {
			union[union.position(of: element)].weight += element.weight
        }
        return union
    }
    
	func intersection(_ other: WeightedSet) -> WeightedSet {
        let intersection = WeightedSet()
        for element in other.elements {
            if contains(element) && other.contains(element) {
				let weight = weight(of: element) + other.weight(of: element)
                intersection[intersection.position(of: element)].weight = weight
            }
        }
        return intersection
    }
    
    func symmetricDifference(_ other: WeightedSet) -> WeightedSet {
        let symmetricDifference = WeightedSet()
        for element in elements {
            if !other.contains(element) {
                symmetricDifference[symmetricDifference.position(of: element)].weight = element.weight
            }
        }
        for element in other.elements {
            if !contains(element) {
                symmetricDifference[symmetricDifference.position(of: element)].weight = element.weight
            }
        }
        return symmetricDifference
    }
    
    func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let inserted = !contains(newMember)
        elements[position(of: newMember)].weight += newMember.weight
        return (inserted, newMember)
    }
    
    func remove(_ member: Element) -> Element? {
        guard contains(member) else { return nil }
        elements[position(of: member)].weight -= member.weight
        return elements[position(of: member)]
    }
    
    func update(with newMember: Element) -> Element? {
        let alreadyContains = contains(newMember)
        elements[position(of: newMember)].weight += newMember.weight
        return alreadyContains ? newMember : nil
    }
    
	func formUnion(_ other: WeightedSet) {
		elements = union(other).elements
    }
    
	func formIntersection(_ other: WeightedSet) {
		elements = intersection(other).elements
    }

	func formSymmetricDifference(_ other: WeightedSet) {
		elements = symmetricDifference(other).elements
    }
    
	func subtract(_ other: WeightedSet) {
		elements = subtracting(other).elements
    }
    
	func subtracting(_ other: WeightedSet) -> WeightedSet {
        // WeightedSet is a class, so copy the elements rather than the reference to avoid changing this set.
        let copy = WeightedSet()
        copy.elements = elements
        for element in other.elements {
            guard let index = copy.existingPosition(of: element) else { continue }
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
    
    // TODO: Remove these when sure the default implementations are enough.
    
    // Set A is a subset of another set B if every member of A is also a member of B.
//	func isSubset(of other: WeightedSet) -> Bool {
//        for element in weightedElements {
//            if !other.contains(element) {
//                return false
//            }
//        }
//        return true
//    }
//    
//    // Set A is a superset of another set B if every member of B is also a member of A.
//    func isSuperset(of other: WeightedSet) -> Bool {
//        other.isSubset(of: self)
//    }
//    
//    // Set A is a strict subset of another set B if every member of A is also a member of B and B contains at least one element that is not a member of A.
//    func isStrictSubset(of other: WeightedSet) -> Bool {
//        if !isSubset(of: other) {
//            return false
//        }
//        return weightedElements.count < other.weightedElements.count
//    }
//    
//    // Set A is a strict superset of another set B if every member of B is also a member of A and A contains at least one element that is not a member of B.
//    func isStrictSuperset(of other: WeightedSet) -> Bool {
//        other.isStrictSubset(of: self)
//    }

}

// MARK: - ExpressibleByArrayLiteral
extension WeightedSet: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = Element
	convenience init(arrayLiteral elements: ArrayLiteralElement...) {
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

	func position(of rawValue: Element.RawValue) -> Int {
		position(of: Element(rawValue: rawValue))
	}

	func contains(rawValue: Element.RawValue) -> Bool {
		contains(Element(rawValue: rawValue))
	}
}
