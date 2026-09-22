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

extension WeightedABCD: Comparable {
    static func < (lhs: WeightedABCD, rhs: WeightedABCD) -> Bool {
        if lhs.weight == rhs.weight {
            return lhs.rawValue.rawValue < rhs.rawValue.rawValue
        }
        return lhs.weight > rhs.weight
    }
}

extension WeightedABCD: Codable {
}

extension WeightedABCD: Hashable {
}

extension WeightedABCD: Identifiable {
	var id: String {
		description
	}
}

extension WeightedABCD: CustomStringConvertible {
    var description: String {
        "\(rawValue)(\(weight))"
    }
}

struct WeightedSetTests {

	var C3B2A1: WeightedSet<WeightedABCD> {
		let set: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
		return set
	}
	
	var C3B2A1D0: WeightedSet<WeightedABCD> {
		let set: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3), .D(0)]
		return set
	}
	
	var D4C3B2A1: WeightedSet<WeightedABCD> {
		let set: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3), .D(4)]
		return set
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
		/*
		 set[0] = B(2)
		 WeightedSet([B(2), C(3), A(1), D(0)])
		 set[1] = C(3)
		 WeightedSet([B(2), C(3), A(1), D(0)])
		 set[1] = D(0)
		 WeightedSet([B(2), D(0), D(0), A(1)])
		 set[3] = C(3)
		 WeightedSet([B(2), D(0), D(0), C(3), A(1)])
		 */
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
        #expect(set.position(of: .A) == 2)
        #expect(set.position(of: .B) == 1)
        #expect(set.position(of: .C) == 0)
        #expect(set.position(of: .D) == 3)
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
        // x.union(x) == x
        #expect(x.union(x) == x)
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
        // x.intersection(x) == x
        #expect(x.intersection(x) == x)
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
        #expect(result.0 == false)
        #expect(result.1 == .A(1))
        result = x.insert(.D(1))
        #expect(x.weight(of: .D) == 1)
        #expect(result.0 == true)
        #expect(result.1 == .D(1))
    }
    
    @Test func testUpdate() {
		let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        var updated = x.update(with: .A(1))
        #expect(x.weight(of: .A) == 2)
        #expect(updated == .A(2))
        updated = x.update(with: .D(1))
        #expect(x.weight(of: .D) == 1)
        #expect(updated == nil)
    }
    
    @Test func testRemove() {
		let x: WeightedSet<WeightedABCD> = [.A(1), .B(2), .C(3)]
        var removed = x.remove(.A(1))
        #expect(x.contains(rawValue: .A) == false)
        #expect(removed == .A(1))
        removed = x.remove(.D(1))
        #expect(x.contains(rawValue: .D) == false)
        #expect(removed == nil)
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
        // x.isSubset(of: y) implies x.union(y) == y
        #expect(x.isSubset(of: y) && x.union(y) == y)
        #expect(( y.isSubset(of: x) && y.union(x) == x )  == false)
    }
    
    @Test func testIsSuperset() {
        let x: WeightedSet<WeightedABCD> = [.A(1), .B(1)]
        let y: WeightedSet<WeightedABCD> = [.A(1)]
        #expect(x.isSuperset(of: y))
        // x.isSuperset(of: y) implies x.union(y) == x
        #expect(x.isSuperset(of: y) && (x.union(y) == x))
        #expect(( y.isSuperset(of: x) && (y.union(x) == y) ) == false)
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
	
    @Test func testMove() {
		var x: WeightedSet<WeightedABCD>
		
		x = [.C(3), .B(2), .A(1)]
		x.move(fromOffsets: [0], toOffset: 0)
        #expect(x.elements == [.C(3), .B(2), .A(1)])

		x = [.C(3), .B(2), .A(1)]
		x.move(fromOffsets: [0], toOffset: 1)
        #expect(x.elements == [.C(3), .B(2), .A(1)])
		
		x = [.C(3), .B(2), .A(1)]
		x.move(fromOffsets: [0], toOffset: 2)
        #expect(x.elements == [.B(2), .C(3), .A(1)])
		
		x = [.C(3), .B(2), .A(1)]
		x.move(fromOffsets: [0], toOffset: 3)
        #expect(x.elements == [.B(2), .A(1), .C(3)])

		x = [.C(3), .B(2), .A(1)]
		x.move(fromOffsets: [1, 2], toOffset: 0)
        #expect(x.elements == [.B(2), .A(1), .C(3)])

		x = [.C(3), .B(2), .A(1)]
		x.move(fromOffsets: [1, 2], toOffset: 1)
        #expect(x.elements == [.C(3), .B(2), .A(1)])
		
		x = [.C(3), .B(2), .A(1)]
		x.move(fromOffsets: [1, 2], toOffset: 2)
        #expect(x.elements == [.C(3), .B(2), .A(1)])
		
		x = [.C(3), .B(2), .A(1)]
		x.move(fromOffsets: [1, 2], toOffset: 3)
        #expect(x.elements == [.C(3), .B(2), .A(1)])
	}
	
    @Test func testElementId() {
        #expect(C3B2A1D0.elements[0].id == "C(3)")
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

}
