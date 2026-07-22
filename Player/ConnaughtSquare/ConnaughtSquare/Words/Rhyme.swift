//
//  Rhyme.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation

/// A rhyme is a represented as a number of phonemes.
struct Rhyme: Equatable, Hashable {
    private let string: String
    
    init(phonemes: [Phoneme]) {
        string = phonemes.map({ $0.description }).joined(separator: "-")
    }
}

// MARK: - Comparable
extension Rhyme: Comparable {
    static func < (lhs: Rhyme, rhs: Rhyme) -> Bool {
		lhs.string < rhs.string
    }
}

// MARK: - CustomStringConvertible
extension Rhyme: CustomStringConvertible {
    var description: String {
        string
    }
}
