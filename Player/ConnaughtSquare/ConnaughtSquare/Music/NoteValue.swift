//
//  NoteValue.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 07/12/2023.
//

/// Note values in in standard musical terminology.
enum NoteValue: UInt8 {
    case d2 = 50
    case dSharp2
    case e2
    case f2
    case fSharp2
    case g2
    case gSharp2
    case a2
    case aSharp2
    case b2
    case c3
    case cSharp3
    case d3
    case dSharp3
    case e3
    case f3
    case fSharp3
    case g3
    case gSharp3
    case a3
    case aSharp3
    case b3
}

extension NoteValue: CaseIterable {
    static var randomValue: NoteValue {
        Self.allCases.randomElement()!
    }
}

extension NoteValue: Comparable {
    static func < (lhs: NoteValue, rhs: NoteValue) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
