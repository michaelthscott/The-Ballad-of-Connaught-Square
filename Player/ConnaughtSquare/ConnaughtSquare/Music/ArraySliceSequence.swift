//
//  ArraySliceSequence.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 05/12/2023.
//

/// Implementation of Sequence protocol on an ArraySlice. This is used in Tune to provide array slices of a specified width
struct ArraySliceSequence<Element>: Sequence {
    private let elements: ArraySlice<Element>
    let width: Int
    
    init(_ elements: Array<Element>, width: UInt) {
        self.init(elements[...], width: width)
    }
    
    init(_ elements: ArraySlice<Element>, width: UInt) {
        self.elements = elements
        self.width = Int(width)
    }

    var isEmpty: Bool {
        return count == 0
    }
    
    var count: Int {
        guard width > 0, elements.count >= width else {
            return 0
        }
        return elements.count - (width - 1)
    }
    
    func makeIterator() -> AnyIterator<ArraySlice<Element>> {
        var sliceStart = elements.startIndex
        return AnyIterator {
            guard sliceStart < self.elements.endIndex else {
                return nil
            }
            let sliceEnd = self.elements.index(sliceStart, offsetBy: self.width)
            guard sliceEnd <= self.elements.endIndex else {
                return nil
            }
            defer {
                self.elements.formIndex(after: &sliceStart)
            }
            return self.elements[sliceStart..<sliceEnd]
        }
    }
}

extension Array {
    func slices(width: UInt) -> ArraySliceSequence<Element> {
		ArraySliceSequence<Element>(self[..<endIndex], width: width)
    }
}

extension ArraySlice {
    func slices(width: UInt) -> ArraySliceSequence<Element> {
        ArraySliceSequence<Element>(self, width: width)
    }
}
