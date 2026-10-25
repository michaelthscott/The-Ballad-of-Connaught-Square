//
//  Cycle.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 19/01/2024.
//

import Foundation

/// A cycle of elements.
struct Cycle<Element: Comparable & Hashable & Sendable>: Sendable {
	let elements: [Element]
	/// The index of the element that `next()` returns, or `endIndex` once the last element has been returned.
	private(set) var currentIndex: [Element].Index
    
    /// A cycle of elements.
    /// - Parameter elements: Throws a fatal error if the array is empty.
	init(elements: [Element]) {
        guard !elements.isEmpty else {
            fatalError("Cycle cannot be initialised with an empty array.")
        }
		self.elements = elements
		currentIndex = elements.startIndex
	}
    
    /// Finds the minimum element.
    /// - Returns: The minimum element.
	func min() -> Element {
        guard let element = elements.min() else {
            fatalError("Failed to find minimum element")
        }
        return element
	}
	
    /// Finds the maximum element.
    /// - Returns: The maximum element.
	func max() -> Element {
        guard let element = elements.max() else {
            fatalError("Failed to find maximum element")
        }
        return element
	}
    
    /// Returns the result of combining the elements of the sequence using the given closure.
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value. `initialResult` is passed to `nextPartialResult` the first time the closure is executed.
    ///   - nextPartialResult: A closure that combines an accumulating value and an element of the sequence into a new accumulating value, to be used in the next call of the `nextPartialResult` closure or returned to the caller.
    /// - Returns: The final accumulated value. If the sequence has no elements, the result is `initialResult`.
	func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Element) throws -> Result) rethrows -> Result {
		try elements.reduce(initialResult, nextPartialResult)
	}
    
    /// Computes the most frequent element.
    ///
    /// When several elements are equally frequent, the greatest of them is returned so that the result is deterministic.
	var mostFrequent: Element {
		var frequencies: [Element: Int] = [:]
		for element in elements {
			frequencies[element, default: 0] += 1
		}
        let mostFrequent = frequencies.max { lhs, rhs in
            lhs.value != rhs.value ? lhs.value < rhs.value : lhs.key < rhs.key
        }
        guard let element = mostFrequent?.key else {
            fatalError("Failed to find the most frequent element")
        }
        return element
	}
    
    /// Partitions the elements into a sequence of slices of the specified width.
    /// - Parameter width: The number of elements to include in a slice.
    /// - Returns: The sequence of slices.
	func slices(width: UInt) -> ArraySliceSequence<Element> {
		ArraySliceSequence<Element>(elements[...], width: width)
	}
}

extension Cycle {
    /// Moves to the next element and returns it.
    /// - Returns: The next element.
	mutating func next() -> Element {
		if currentIndex == elements.endIndex {
			currentIndex = elements.startIndex
		}
		defer { elements.formIndex(after: &currentIndex) }
		return elements[currentIndex]
	}
}

// MARK - ExpressibleByArrayLiteral
extension Cycle: ExpressibleByArrayLiteral {
	typealias ArrayLiteralElement = Element
	init(arrayLiteral elements: Element...) {
        self.init(elements: elements)
	}
}

// MARK - Hashable
extension Cycle: Hashable {
    func hash(into hasher: inout Hasher) {
        for element in elements {
            hasher.combine(element)
        }
    }
}

