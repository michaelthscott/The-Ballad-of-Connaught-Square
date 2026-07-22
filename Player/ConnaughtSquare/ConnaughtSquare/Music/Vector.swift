//
//  Vector.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 16/12/2023.
//

import Foundation

struct Vector<Element: Codable & Equatable & Comparable & Hashable>: Weighted {
	let elements: [Element]
	var weight: Int
	
	init(_ elements: [Element], weight: Int = 0) {
		self.elements = elements
		self.weight = weight
	}
}

extension Vector: Comparable {
    static func < (lhs: Vector<Element>, rhs: Vector<Element>) -> Bool {
		guard lhs.elements.count == rhs.elements.count else {
			return lhs.elements.count < rhs.elements.count
		}
		for index in lhs.elements.indices {
			if lhs.elements[index] < rhs.elements[index] {
				return true
			}
		}
		return false
    }
    
    static func == (lhs: Vector<Element>, rhs: Vector<Element>) -> Bool {
        lhs.elements == rhs.elements
    }
}

extension Vector: Hashable {
	
}

extension Vector: Codable {
    enum CodingKeys: String, CodingKey {
        case elements, weight
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(elements, forKey: .elements)
        try container.encode(weight, forKey: .weight)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let elements = try container.decode([Element].self, forKey: .elements)
        let weight = try container.decode(Int.self, forKey: .weight)
		self.init(elements)
		self.weight = weight
    }
}

// MARK: - ExpressibleByArrayLiteral
extension Vector: ExpressibleByArrayLiteral {
	typealias ArrayLiteralElement = Element
	
	init(arrayLiteral elements: ArrayLiteralElement...) {
		self.init(elements)
	}
}

// MARK: - Sequence
extension Vector: Sequence {
	var isEmpty: Bool {
		elements.isEmpty
	}
	
	var count: Int {
		elements.count
	}
	
	func makeIterator() -> Array<Element>.Iterator {
		elements.makeIterator()
	}
}

// MARK: - Collection
extension Vector: Collection {
	var startIndex: Int {
		elements.startIndex
	}
	
	var endIndex: Int {
		elements.endIndex
	}
	
	// We use this in Composer.compose() to access the intervals and durations.
	
	subscript(index: Int) -> Element {
		elements[index]
	}
	
	// TODO: Could return Vector<Element>. I don't think this is actually used.
//    subscript(bounds: Range<Array<Element>.Index>) -> ArraySlice<Element> {
//        elements[bounds]
//    }
	
	func index(after i: Array<Element>.Index) -> Array<Element>.Index {
		elements.index(after: i)
	}
}

// MARK: - CustomStringConvertible
extension Vector: CustomStringConvertible {
	var description: String {
		"Vector(\(elements)], weight: \(weight))"
	}
}

