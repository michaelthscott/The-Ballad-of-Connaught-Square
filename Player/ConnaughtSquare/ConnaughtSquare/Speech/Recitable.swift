//
//  Recitable.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 25/12/2023.
//

// TODO: Not used.

protocol Recitable {
	associatedtype Element: Recitable
	var elements: ArraySlice<Element> { get set }
	var isRecited: Bool { get set }
	var recitedElements: ArraySlice<Element> { get }
	var unrecitedElements: ArraySlice<Element> { get }
}

extension Recitable {
	var isRecited: Bool {
		get {
			for element in elements {
				if element.isRecited {
					return true
				}
			}
			return false
		}
		set {
			for var element in elements {
				element.isRecited = newValue
			}
		}
	}
	
	var recitedElements: ArraySlice<Element> {
		elements.prefix { $0.isRecited }
	}
		
	var unrecitedElements: ArraySlice<Element> {
		guard let index = elements.firstIndex(where: { !$0.isRecited }) else { return elements.suffix(from: elements.endIndex) }
		return elements[index..<elements.endIndex]
	}

}
