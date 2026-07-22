//
//  BalladCursor.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 10/04/2025.
//

import Foundation

struct BalladCursor: CustomStringConvertible {
    var cantoIndex: Int
    var stanzaIndex: Int
    var lineIndex: Int
    var partIndex: Int
    
    var description: String {
        "BalladCursor(Canto: \(cantoIndex), Stanza: \(stanzaIndex), Line: \(lineIndex), Part: \(partIndex))"
    }
}

struct BalladCursorSequence: Sequence, IteratorProtocol {
    typealias Element = BalladCursor
    let cantos: [Canto]
    var cursor: BalladCursor!
    
    init(ballad: Ballad) {
        cantos = ballad.cantos
        cursor = startCursor()
    }
    
    private mutating func startCursor() -> BalladCursor {
        let cantoIndex = cantos.startIndex
        let stanzaIndex = cantos[cantoIndex].stanzas.startIndex
        let lineIndex = cantos[cantoIndex].stanzas[stanzaIndex].lines.startIndex
        let partIndex = cantos[cantoIndex].stanzas[stanzaIndex].lines[lineIndex].parts.startIndex
        return BalladCursor(cantoIndex: cantoIndex, stanzaIndex: stanzaIndex, lineIndex: lineIndex, partIndex: partIndex)
    }
    
    mutating func next() -> BalladCursor? {
        guard cursor.cantoIndex < cantos.endIndex else { return nil }
        guard cursor.stanzaIndex < cantos[cursor.cantoIndex].stanzas.endIndex else { return nil }
        guard cursor.lineIndex < cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines.endIndex else { return nil }
        guard cursor.partIndex < cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines[cursor.lineIndex].parts.endIndex else { return nil }
        
        // If there are still parts in the current line then increment the part index in the cursor.
        if remainingParts > 0 {
            cursor.partIndex = cursor.partIndex + 1
            return cursor
        }
        // if there are still lines in the current stanza then increment the line index and reset the part index to the start.
        if remainingLines > 0 {
            cursor.lineIndex = cursor.lineIndex + 1
            cursor.partIndex = cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines[cursor.lineIndex].parts.startIndex
            return cursor
        }
        // if there are still stanzas in the current canto then increment the stanza index and reset the line and the part indices to the start.
        if remainingStanzas > 0 {
            cursor.stanzaIndex = cursor.stanzaIndex + 1
            cursor.lineIndex = cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines.startIndex
            cursor.partIndex = cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines[cursor.lineIndex].parts.startIndex
            return cursor
        }
        // if there are still cantos then increment the canto index and reset the stanza, line and part indices to the start.
        if remainingCantos > 0 {
            cursor.cantoIndex = cursor.cantoIndex + 1
            cursor.stanzaIndex = cantos[cursor.cantoIndex].stanzas.startIndex
            cursor.lineIndex = cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines.startIndex
            cursor.partIndex = cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines[cursor.lineIndex].parts.startIndex
            return cursor
        }
        // Otherwise reset the cursor to the start and indicate the end.
        cursor = startCursor()
        return nil
    }
    
    var currentPart: Part {
        cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines[cursor.lineIndex].parts[cursor.partIndex]
    }
    
    var remainingCantos: Int {
        cantos.endIndex - cursor.cantoIndex - 1
    }
    
    var remainingStanzas: Int {
        cantos[cursor.cantoIndex].stanzas.endIndex - cursor.stanzaIndex - 1
    }
    
    var remainingLines: Int {
        cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines.endIndex - cursor.lineIndex - 1
    }

    var remainingParts: Int {
        cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines[cursor.lineIndex].parts.endIndex - cursor.partIndex - 1
    }
    
    var isStartOfBallad: Bool {
        cantos.startIndex == cursor.cantoIndex && isStartOfCanto && isStartOfStanza && isStartOfLine
    }

    var isStartOfCanto: Bool {
        cantos[cursor.cantoIndex].stanzas.startIndex == cursor.stanzaIndex && isStartOfStanza && isStartOfLine
    }
    
    var isStartOfStanza: Bool {
        cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines.startIndex == cursor.lineIndex && isStartOfLine
    }

    var isStartOfLine: Bool {
        cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines[cursor.lineIndex].parts.startIndex == cursor.partIndex
    }

    
}
