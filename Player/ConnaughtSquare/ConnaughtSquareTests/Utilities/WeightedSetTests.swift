//
//  WeightedSetTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 12/12/2023.
//

import Testing
import SwiftUI
@testable import ConnaughtSquare

enum ABCD: String {
    case A = "A"
    case B = "B"
    case C = "C"
    case D = "D"
}

enum WeightedABCD: Weighted {
    case A(_ weight: Int = 0)
    case B(_ weight: Int = 0)
    case C(_ weight: Int = 0)
    case D(_ weight: Int = 0)

    var weight: Int {
        get {
            switch self {
            case .A(let weight):
                return weight
            case .B(let weight):
                return weight
            case .C(let weight):
                return weight
            case .D(let weight):
                return weight
            }
        }
        mutating set {
            switch self {
            case .A(_):
                self = .A(newValue)
            case .B(_):
                self = .B(newValue)
            case .C(_):
                self = .C(newValue)
            case .D(_):
                self = .D(newValue)
            }
        }
    }
}

extension WeightedABCD: SafeRawRepresentable {
    init(rawValue: ABCD) {
        switch rawValue {
        case ABCD.A:
            self = .A()
        case ABCD.B:
            self = .B()
        case ABCD.C:
            self = .C()
        case ABCD.D:
            self = .D()
        }
    }
    
    var rawValue: ABCD {
        switch self {
        case .A(_):
            return ABCD.A
        case .B(_):
            return ABCD.B
        case .C(_):
            return ABCD.C
        case .D(_):
            return ABCD.D
        }
    }
}

extension WeightedABCD: CaseIterable {
    static var allCases: [WeightedABCD] {
        [.A(), .B(), .C(), .D()]
    }
}

// Overriding the protocol default implementation.
extension WeightedABCD: Equatable {
	static func == (lhs: WeightedABCD, rhs: WeightedABCD) -> Bool {
		lhs.rawValue == rhs.rawValue
	}
	static func == (lhs: WeightedABCD, rhs: ABCD) -> Bool {
		lhs.rawValue == rhs
	}
}

// Like `==`, ordering and hashing ignore the weight, as `Weighted` requires.
extension WeightedABCD: Comparable {
    static func < (lhs: WeightedABCD, rhs: WeightedABCD) -> Bool {
        lhs.rawValue.rawValue < rhs.rawValue.rawValue
    }
}

extension WeightedABCD: Codable {
}

extension WeightedABCD: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
}

extension WeightedABCD: Identifiable {
	var id: String {
		rawValue.rawValue
	}
}

extension WeightedABCD: CustomStringConvertible {
    var description: String {
        "\(rawValue)(\(weight))"
    }
}

struct WeightedSetTests {

	// `init` sorts by the elements' `<`, which ignores weight, so these fixtures sort by weight
	// themselves, heaviest first, to give the order their names describe.
	private func heaviestFirst(_ elements: [WeightedABCD]) -> WeightedSet<WeightedABCD> {
		var set = WeightedSet<WeightedABCD>(elements)
		set.sort { $0.weight > $1.weight }
		return set
	}

	var C3B2A1: WeightedSet<WeightedABCD> {
		heaviestFirst([.A(1), .B(2), .C(3)])
	}

	var C3B2A1D0: WeightedSet<WeightedABCD> {
		heaviestFirst([.A(1), .B(2), .C(3), .D(0)])
	}

	var D4C3B2A1: WeightedSet<WeightedABCD> {
		heaviestFirst([.A(1), .B(2), .C(3), .D(4)])
	}
	
    @Test func testEquatable() {
        let set1 = C3B2A1
        let set2 = D4C3B2A1
        #expect(WeightedSet<WeightedABCD>(set1) == WeightedSet<WeightedABCD>(set1))
        #expect(WeightedSet<WeightedABCD>(set1) != WeightedSet<WeightedABCD>(set2))
    }
   
    @Test func testSubscriptPosition() {
		var set: WeightedSet<WeightedABCD>
		
		set = C3B2A1
        #expect(set[0] == .C)
        #expect(set[1] == .B)
        #expect(set[2] == .A)
		set[0] = .A(4)
        #expect(set[0] == .A && set[0].weight == 4)
        #expect(set[1] == .C && set[1].weight == 3)
        #expect(set[2] == .B && set[2].weight == 2)
		
		set = C3B2A1
        #expect(set[0] == .C(3))
        #expect(set[1] == .B(2))
        #expect(set[2] == .A(1))
		set[1] = .A(4)
        #expect(set[0] == .C && set[0].weight == 3)
        #expect(set[1] == .A && set[1].weight == 4)
        #expect(set[2] == .B && set[2].weight == 2)
		
		set = C3B2A1
        #expect(set[0] == .C(3))
        #expect(set[1] == .B(2))
        #expect(set[2] == .A(1))
		set[2] = .C(5)
        #expect(set[0] == .B && set[0].weight == 2)
        #expect(set[1] == .A && set[1].weight == 1)
        #expect(set[2] == .C && set[2].weight == 5)
		
		set = C3B2A1
        #expect(set[0] == .C(3))
        #expect(set[1] == .B(2))
        #expect(set[2] == .A(1))
		print(set)
		set[1] = .C(5)
		print(set)
        #expect(set[0] == .B && set[0].weight == 2)
        #expect(set[1] == .C && set[1].weight == 5)
        #expect(set[2] == .A && set[2].weight == 1)
	}
	
    @Test func testSubscriptPositionFailure() {
		// This sequence once left D(0) in the set twice. It now keeps every element exactly once.
		let set = C3B2A1D0
		set[0] = .B(2)
		set[1] = .C(3)
		set[1] = .D(0)
		set[3] = .C(3)
        #expect(set[0] == .B && set[0].weight == 2)
        #expect(set[1] == .D && set[1].weight == 0)
        #expect(set[2] == .A && set[2].weight == 1)
        #expect(set[3] == .C && set[3].weight == 3)
	}
	
    @Test func testSubscriptBounds() {
		var set: WeightedSet<WeightedABCD>
		
		set = C3B2A1D0
        #expect(set[0..<1] == [.C(3)])
        #expect(set[1..<2] == [.B(2)])
        #expect(set[2..<3] == [.A(1)])
        #expect(set[3..<4] == [.D(0)])
        #expect(set[0..<2] == [.C(3), .B(2)])
        #expect(set[1..<3] == [.B(2), .A(1)])
        #expect(set[...] == [.C(3), .B(2), .A(1), .D(0)])
        #expect(set[...1] == [.C(3), .B(2)])
        #expect(set[1...] == [.B(2), .A(1), .D(0)])
		set[0..<1] = [.A(4)]
        #expect(set[0] == .A())
        #expect(set[1] == .C(3))
        #expect(set[2] == .B(2))

		set = C3B2A1
		set[0..<2] = [.A(1), .C(3)]
        #expect(set[0] == .A(1))
        #expect(set[1] == .C(3))
        #expect(set[2] == .B(2))
		
		set = C3B2A1
		set[0..<3] = [.A(1), .B(2), .C(3)]
        #expect(set[0] == .A(1))
        #expect(set[1] == .B(2))
        #expect(set[2] == .C(3))
	}

	/// Assigning a range an element that sits before it moves the element towards the end,
	/// which used to land it one place short and overwrite another element.
    @Test func testSubscriptBoundsMovingTowardsTheEnd() {
		let set = C3B2A1
		set[1..<2] = [.C(3)]
        #expect(set.elements.map(\.description) == ["B(2)", "C(3)", "A(1)"])

		let other = C3B2A1D0
		other[2..<4] = [.C(3), .B(2)]
        #expect(other.elements.map(\.description) == ["A(1)", "D(0)", "C(3)", "B(2)"])
	}

	// TODO: More tests.
    @Test func testCompareSubscriptPositionAndMove() {
		let x = C3B2A1D0
		var y = C3B2A1D0
		x[0] = .D(0)
		y.move(fromOffsets: [3], toOffset: 0)
        #expect(x == y)
	}
	
    @Test func testCollection() {
        let set = C3B2A1
        #expect(WeightedSet<WeightedABCD>().isEmpty == true)
        #expect(set.isEmpty == false)
        #expect(set.count == 3)
        #expect(set.indices == 0..<3)
        #expect(set.startIndex == 0)
        #expect(set.endIndex == set.count)
        #expect(set.index(after: set.startIndex) == set.startIndex + 1)
        #expect(set.index(after: set.endIndex - 1) == set.endIndex)
    }
    
    @Test func testWeight() {
		let set = C3B2A1
        #expect(set.weight(of: .A) == 1)
        #expect(set.weight(of: .B) == 2)
        #expect(set.weight(of: .C) == 3)
        #expect(set.weight(of: .D) == 0)
    }
    
    @Test func testIndex() {
		let set = C3B2A1
        #expect(set.firstIndex(of: .A()) == 2)
        #expect(set.firstIndex(of: .B()) == 1)
        #expect(set.firstIndex(of: .C()) == 0)
        // Looking up a missing element doesn't add it.
        #expect(set.firstIndex(of: .D()) == nil)
        #expect(set.count == 3)
    }

    @Test func testSetWeight() {
		let set = C3B2A1
		set.setWeight(5, of: .B())
        #expect(set.weight(of: .B) == 5)
        #expect(set.firstIndex(of: .B()) == 1)
		// A missing element is added at the end, and the element's own weight is ignored.
		set.setWeight(4, of: .D(9))
        #expect(set.weight(of: .D) == 4)
        #expect(set.firstIndex(of: .D()) == 3)
		set.setWeight(0, of: .A())
        #expect(set.contains(rawValue: .A) == false)
        #expect(set.count == 4)
    }

    @Test func testAddWeight() {
		let set = C3B2A1
		set.addWeight(2, to: .A())
        #expect(set.weight(of: .A) == 3)
		set.addWeight(1, to: .D(9))
        #expect(set.weight(of: .D) == 1)
        #expect(set.elements.map(\.description) == ["C(3)", "B(2)", "A(3)", "D(1)"])
    }

    @Test func testShuffleUsingAGeneratorKeepsTheElements() {
		var generator = SeededRandomNumberGenerator(seed: 7)
		let set = D4C3B2A1
		set.shuffle(using: &generator)
        #expect(Set(set.elements.map(\.description)) == ["A(1)", "B(2)", "C(3)", "D(4)"])
        #expect(set.count == 4)
    }
    
    @Test func testInitElements() {
		let set = C3B2A1
		let copy: WeightedSet<WeightedABCD> = [.A(1), .B(1), .C(1), .B(1), .C(1), .C(1), .D(0)]
        #expect(set == copy)
    }
    
    // TODO: How does this test Sequence.
    @Test func testSequence() {
		let set = C3B2A1D0
        var string = ""
        for element in set {
            string += element.description
        }
        #expect(string == "C(3)B(2)A(1)D(0)")
    }
    
    @Test func testDescription() {
		let set = C3B2A1D0
        #expect(set.description == "WeightedSet([C(3), B(2), A(1), D(0)])")
    }
    
    // S() == []
    @Test func testEmptySet() {
        #expect(WeightedSet<WeightedABCD>() == [])
    }
    
    @Test func testContains() {
        let set: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        #expect(set.contains(rawValue: .A))
        #expect(set.contains(rawValue: .D) == false)
    }
    
    @Test func testUnion() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        let expected: WeightedSet<WeightedABCD> = [.C(5), .B(3), .D(3), .A(1)]
        #expect(x.union(y) == expected)
        // Union adds the weights, so x.union(x) doubles them rather than equalling x.
        #expect(x.union(x) != x)
        #expect(x.union(x) == [.A(2), .B(4), .C(6)])
        // x.union([]) == x
        #expect(x.union(WeightedSet()) == x)
        // x.contains(e) implies x.union(y).contains(e)
        #expect(x.contains(rawValue: .A) && x.union(y).contains(rawValue: .A))
        // x.union(y).contains(e) implies x.contains(e) || y.contains(e)
        #expect(x.union(y).contains(rawValue: .A) && (x.contains(rawValue: .A) || y.contains(rawValue: .A)))
    }
    
    @Test func testIntersection() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        let expected: WeightedSet<WeightedABCD> = [.B(3), .C(5)]

        #expect(expected.weight(of: .A) == 0)
        #expect(x.weight(of: .B) + y.weight(of: .B) == 3)
        #expect(expected.weight(of: .B) == x.weight(of: .B) + y.weight(of: .B))
        // expected = WeightedSet<WeightedABCD>(elements: [C(5), B(3), A(0), D(0)])
        // x.intersection(y) = WeightedSet<WeightedABCD>(elements: [A(6), B(4), C(2), D(0)])
        #expect(x.intersection(y) == expected)
        // Intersection adds the weights too, so x.intersection(x) doubles them.
        #expect(x.intersection(x) == [.A(2), .B(4), .C(6)])
        // x.intersection([]) == []
        #expect(x.intersection(WeightedSet()) == WeightedSet())
        // x.contains(e) && y.contains(e) if and only if x.intersection(y).contains(e)
        #expect(x.contains(rawValue: .B) && y.contains(rawValue: .B) && x.intersection(y).contains(rawValue: .B))
        #expect(( x.contains(rawValue: .A) && y.contains(rawValue: .A) && x.intersection(y).contains(rawValue: .A) ) == false)
    }
    
    @Test func testSymmetricDifference() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        let expected: WeightedSet<WeightedABCD> = [.A(1), .D(3)]
        #expect(expected.weight(of: .A) == x.weight(of: .A))
        #expect(expected.weight(of: .D) == y.weight(of: .D))
        #expect(expected.weight(of: .B) == 0)
        #expect(x.symmetricDifference(y) == expected)
    }
    
    @Test func testInsert() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        var result = x.insert(.A(1))
        #expect(x.weight(of: .A) == 2)
        #expect(result.inserted == false)
        // The member after the insertion carries the new total weight.
        #expect(result.memberAfterInsert == .A && result.memberAfterInsert.weight == 2)
        result = x.insert(.D(1))
        #expect(x.weight(of: .D) == 1)
        #expect(result.inserted == true)
        #expect(result.memberAfterInsert == .D && result.memberAfterInsert.weight == 1)
    }

    @Test func testInsertWithoutWeightIsNotAnInsertion() {
        let x: WeightedSet<WeightedABCD> = [.A(1)]
        let result = x.insert(.B(0))
        #expect(result.inserted == false)
        #expect(x.contains(rawValue: .B) == false)
    }

    @Test func testUpdate() {
		let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        // Updating replaces the weight, and returns the element as it was.
        var updated = x.update(with: .A(5))
        #expect(x.weight(of: .A) == 5)
        #expect(updated?.description == "A(1)")
        updated = x.update(with: .D(1))
        #expect(x.weight(of: .D) == 1)
        #expect(updated == nil)
    }

    @Test func testRemove() {
		let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        var removed = x.remove(.A(1))
        #expect(x.contains(rawValue: .A) == false)
        // The removed member keeps the weight it had before the removal.
        #expect(removed?.description == "A(1)")
        removed = x.remove(.D(1))
        #expect(x.contains(rawValue: .D) == false)
        #expect(removed == nil)
        removed = x.remove(.C(1))
        #expect(removed?.description == "C(3)")
        #expect(x.weight(of: .C) == 2)
    }

    @Test func testRemoveStopsAtZero() {
        let x: WeightedSet<WeightedABCD> = [.A(2)]
        let removed = x.remove(.A(5))
        #expect(removed?.description == "A(2)")
        #expect(x.weight(of: .A) == 0)
        #expect(x.contains(rawValue: .A) == false)
        #expect(x.remove(.A(1)) == nil)
    }

    @Test func testRemoveWithoutWeightRemovesTheWholeWeight() {
        let x: WeightedSet<WeightedABCD> = [.A(2), .B(3)]
        let removed = x.remove(.B(0))
        #expect(removed?.description == "B(3)")
        #expect(x.contains(rawValue: .B) == false)
        #expect(x.weight(of: .A) == 2)
    }

    @Test func testIsEmptyIgnoresZeroWeights() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(2)]
        #expect(x.isEmpty == false)
        #expect(x.subtracting(x).isEmpty)
        let zeros: WeightedSet<WeightedABCD> = [.A(0), .B(0)]
        #expect(zeros.isEmpty)
        #expect(zeros.count == 2)
    }
    
    @Test func testFormUnion() {
		let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        let expected: WeightedSet<WeightedABCD> = [.C(5), .B(3), .D(3), .A(1)]
        x.formUnion(y)
        #expect(x == expected)
    }
    
    @Test func testFormIntersection() {
		let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        let expected: WeightedSet<WeightedABCD> = [.B(3), .C(5)]
        x.formIntersection(y)
        #expect(x == expected)
    }
    
    @Test func testFormSymmetricDifference() {
		let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        let expected: WeightedSet<WeightedABCD> = [.A(1), .D(3)]
        x.formSymmetricDifference(y)
        #expect(x == expected)
    }
    
    @Test func testIsDisjoint() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(2)]
        let y: WeightedSet<WeightedABCD> = [.C(2), .D(3)]
        #expect(x.isDisjoint(with: y))
    }
    
    @Test func testIsSubset() {
        let x: WeightedSet<WeightedABCD> = [.A(1)]
        let y: WeightedSet<WeightedABCD> = [.A(1), .B(1)]
        #expect(x.isSubset(of: y))
        #expect(y.isSubset(of: x) == false)
        #expect(x.isSubset(of: x))
        #expect(WeightedSet<WeightedABCD>().isSubset(of: x))
        // Each element needs at least as much weight in the other set.
        let heavier: WeightedSet<WeightedABCD> = [.A(2)]
        #expect(heavier.isSubset(of: y) == false)
        #expect(x.isSubset(of: heavier))
        // Zero-weight slots don't count.
        let zero: WeightedSet<WeightedABCD> = [.A(1), .D(0)]
        #expect(zero.isSubset(of: y))
    }
    
    @Test func testIsSuperset() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(1)]
        let y: WeightedSet<WeightedABCD> = [.A(1)]
        #expect(x.isSuperset(of: y))
        #expect(y.isSuperset(of: x) == false)
        // x.isSubset(of: y) if and only if y.isSuperset(of: x)
        #expect(y.isSubset(of: x) && x.isSuperset(of: y))
        #expect(( x.isSubset(of: y) && y.isSuperset(of: x) ) == false)
    }
    
    @Test func testIsStrictSubset() {
        let x: WeightedSet<WeightedABCD> = [.A(1)]
        let y: WeightedSet<WeightedABCD> = [.A(1), .B(1)]
        #expect(x.isStrictSubset(of: y))
        #expect(x.isStrictSubset(of: x) == false)
        // x.isStrictSubset(of: y) if and only if x.isSubset(of: y) && x != y
        #expect(x.isStrictSubset(of: y) && x.isSubset(of: y) && x != y)
        #expect(( y.isStrictSubset(of: x) && y.isSubset(of: x) && x != y ) == false)
    }
    
    @Test func testIsStrictSuperset() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(1)]
        let y: WeightedSet<WeightedABCD> = [.A(1)]
        #expect(x.isStrictSuperset(of: y))
        #expect(x.isStrictSuperset(of: x) == false)
        // x.isStrictSuperset(of: y) if and only if x.isSuperset(of: y) && x != y
        #expect(x.isStrictSuperset(of: y) && x.isSuperset(of: y) && x != y)
        #expect(( y.isStrictSuperset(of: x) && y.isSuperset(of: x) && x != y ) == false)
    }
    
    @Test func testSubtract() {
		let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        let expected: WeightedSet<WeightedABCD> = [.A(1), .B(1), .C(1)]
        x.subtract(y)
        #expect(x == expected )
    }
    
    @Test func testSubtracting() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        let expected: WeightedSet<WeightedABCD> = [.A(1), .B(1), .C(1)]
        let subtracting = x.subtracting(y)
        #expect(subtracting == expected)
    }

    @Test func testSubtractingLeavesTheSetUnchanged() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        _ = x.subtracting(y)
        #expect(x.elements.count == 3)
        #expect(x.weight(of: .B) == 2)
        #expect(x.weight(of: .C) == 3)
    }

    @Test func testLookupsLeaveTheSetUnchanged() {
        let set = C3B2A1
        #expect(set.firstIndex(of: .D()) == nil)
        #expect(set.weight(of: .D) == 0)
        #expect(set.contains(.D()) == false)
        #expect(set.elements.count == 3)
    }

    @Test func testSetOperationsLeaveTheOperandsUnchanged() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        let y: WeightedSet<WeightedABCD> = [.B(1), .C(2), .D(3)]
        _ = x.intersection(y)
        _ = x.symmetricDifference(y)
        #expect(x.elements.count == 3)
        #expect(y.elements.count == 3)
    }
	
    @Test func testMove() {
		var x: WeightedSet<WeightedABCD>
		
		x = C3B2A1
		x.move(fromOffsets: [0], toOffset: 0)
        #expect(x.elements == [.C(3), .B(2), .A(1)])

		x = C3B2A1
		x.move(fromOffsets: [0], toOffset: 1)
        #expect(x.elements == [.C(3), .B(2), .A(1)])
		
		x = C3B2A1
		x.move(fromOffsets: [0], toOffset: 2)
        #expect(x.elements == [.B(2), .C(3), .A(1)])
		
		x = C3B2A1
		x.move(fromOffsets: [0], toOffset: 3)
        #expect(x.elements == [.B(2), .A(1), .C(3)])

		x = C3B2A1
		x.move(fromOffsets: [1, 2], toOffset: 0)
        #expect(x.elements == [.B(2), .A(1), .C(3)])

		x = C3B2A1
		x.move(fromOffsets: [1, 2], toOffset: 1)
        #expect(x.elements == [.C(3), .B(2), .A(1)])
		
		x = C3B2A1
		x.move(fromOffsets: [1, 2], toOffset: 2)
        #expect(x.elements == [.C(3), .B(2), .A(1)])
		
		x = C3B2A1
		x.move(fromOffsets: [1, 2], toOffset: 3)
        #expect(x.elements == [.C(3), .B(2), .A(1)])
	}
	
    @Test func testElementId() {
        // The id is the name alone, so it doesn't change with the weight.
        #expect(C3B2A1D0.elements[0].id == "C")
	}

    @Test func testInitSortsByName() {
        let set: WeightedSet<WeightedABCD> = [.C(3), .A(1), .B(2)]
        #expect(set.elements.map(\.description) == ["A(1)", "B(2)", "C(3)"])
    }

    @Test func testEqualElementsHashAlike() {
        #expect(WeightedABCD.A(1).hashValue == WeightedABCD.A(5).hashValue)
        #expect(Set<WeightedABCD>([.A(1), .A(5)]).count == 1)
    }

    /// Equality counts the weights, but not the order of the elements or zero-weight slots.
    @Test func testEqualityCountsWeights() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(5)]
        #expect(x != [.A(5), .B(1)])
        #expect(x != [.A(1)])
        #expect(x == [.B(5), .A(1), .C(0)])
        #expect(C3B2A1 == [.A(1), .B(2), .C(3)])
        #expect(C3B2A1 != D4C3B2A1)
        let a: WeightedSet<WeightedABCD> = [.A(1)]
        #expect(a != [.A(5)])
    }

    @Test func testEqualSetsHashAlike() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(5)]
        let y: WeightedSet<WeightedABCD> = [.B(5), .A(1), .C(0)]
        #expect(x.hashValue == y.hashValue)
        #expect(Set([x, y]).count == 1)
    }
	
    @Test func testFormIndex() {
		var index = 1
		C3B2A1D0.formIndex(before: &index)
        #expect(index == 0)
		C3B2A1D0.formIndex(after: &index)
        #expect(index == 1)
	}
	
    @Test func testShuffle() {
		var set = WeightedSet<WeightedLinguisticTag>(WeightedLinguisticTag.allCases)
		let description = set.description
		set.shuffle()
        #expect(description != set.description)
	}
	
    @Test func testReverse() {
		var set = C3B2A1D0
        #expect(set[0] == .C && set[0].weight == 3)
        #expect(set[1] == .B && set[1].weight == 2)
        #expect(set[2] == .A && set[2].weight == 1)
        #expect(set[3] == .D && set[3].weight == 0)
		set.reverse()
        #expect(set[3] == .C && set[3].weight == 3)
        #expect(set[2] == .B && set[2].weight == 2)
        #expect(set[1] == .A && set[1].weight == 1)
        #expect(set[0] == .D && set[0].weight == 0)
	}

    @Test func testWeightedRandomElementIsProportionalToWeight() throws {
        var generator = SeededRandomNumberGenerator(seed: 42)
        let set = C3B2A1D0
        var counts: [ABCD: Int] = [:]
        let draws = 6000
        for _ in 0..<draws {
            let element = try #require(set.weightedRandomElement(using: &generator))
            counts[element.rawValue, default: 0] += 1
        }
        // Expected shares are 1/6, 2/6 and 3/6; D has no weight so is never chosen.
        #expect(counts[.D] == nil)
        #expect((800...1200).contains(counts[.A] ?? 0))
        #expect((1800...2200).contains(counts[.B] ?? 0))
        #expect((2800...3200).contains(counts[.C] ?? 0))
    }

    @Test func testWeightedRandomElementWithoutWeights() {
        var generator = SeededRandomNumberGenerator(seed: 42)
        let empty = WeightedSet<WeightedABCD>()
        let unweighted: WeightedSet<WeightedABCD> = [.A(0), .B(0)]
        #expect(empty.weightedRandomElement(using: &generator) == nil)
        #expect(unweighted.weightedRandomElement(using: &generator) == nil)
    }

}

/// A deterministic random number generator (SplitMix64) so that tests of random selection are repeatable.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
