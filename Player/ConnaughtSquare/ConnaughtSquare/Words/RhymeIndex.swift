//
//  RhymeIndex.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation
import Accessibility

/// A means of identifying where rhymes appear.
struct RhymeIndex {
    let rhyme: Rhyme?
    let index: Int
    var isUnused: Bool
    
    init(rhyme: Rhyme?, index: Int) {
        self.rhyme = rhyme
        self.index = index
        isUnused = true
    }
}

// MARK: - CustomStringConvertible
extension RhymeIndex: CustomStringConvertible {
    var description: String {
        let rhymeString = rhyme != nil ? rhyme!.description : "-"
        let useString = isUnused ? "unused" : "used"
        return "(\(index), \(rhymeString), \(useString))"
    }
}

// MARK: - [RhymeIndex]
extension Array where Element == RhymeIndex {
    /// The first unused rhyme index in the array.
    /// - Returns: The first unused rhyme index.
    func firstUnusedIndex() -> Int? {
        guard let index = firstIndex(where: { $0.isUnused }) else {
            return nil
        }
        return index
    }
    
    /// The first unused rhyme index in the array matching the specified rhyme.
    /// - Parameter rhyme: A rhyme.
    /// - Returns: The first unused rhyme index that matches the specified rhyme.
    mutating func firstUnusedIndex(prefering rhyme: Rhyme?) -> Int? {
        guard let rhyme = rhyme, let rhymeIndex = firstIndex(where: { $0.isUnused && ($0.rhyme == rhyme) }) else {
            return firstUnusedIndex()
        }
        return rhymeIndex
    }
    
    /// The first unused rhyme index in the array that doesn't match the specified rhyme.
    /// - Parameter rhyme: A rhyme.
    /// - Returns: The first unused rhyme index that does not matches the specified rhyme
    mutating func firstUnusedIndex(avoiding rhyme: Rhyme?) -> Int? {
        guard let rhyme = rhyme, let rhymeIndex = firstIndex(where: { $0.isUnused && ($0.rhyme != rhyme) }) else {
            return firstUnusedIndex()
        }
        return rhymeIndex
    }
}
