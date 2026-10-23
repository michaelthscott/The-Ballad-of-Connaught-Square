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

/// Steps through the parts of a ballad in order, once.
///
/// The cursor starts on the first part. Each call to `next()` moves it on to the following part and
/// returns it, or returns `nil` once the last part has been passed, after which the cursor is `nil`.
/// A ballad with no parts has no cursor from the start.
struct BalladCursorSequence: Sequence, IteratorProtocol {
    typealias Element = BalladCursor
    let cantos: [Canto]
    /// The position of every part of the ballad, in order. Cantos, stanzas and lines without any
    /// parts have no positions, so they are skipped.
    private let cursors: [BalladCursor]
    /// The index in `cursors` of the current part.
    private var position: Int

    init(ballad: Ballad) {
        cantos = ballad.cantos
        var cursors: [BalladCursor] = []
        for (cantoIndex, canto) in zip(cantos.indices, cantos) {
            for (stanzaIndex, stanza) in zip(canto.stanzas.indices, canto.stanzas) {
                for (lineIndex, line) in zip(stanza.lines.indices, stanza.lines) {
                    for partIndex in line.parts.indices {
                        cursors.append(BalladCursor(cantoIndex: cantoIndex, stanzaIndex: stanzaIndex, lineIndex: lineIndex, partIndex: partIndex))
                    }
                }
            }
        }
        self.cursors = cursors
        position = cursors.startIndex
    }

    /// The position of the current part, or `nil` if every part has been passed.
    var cursor: BalladCursor? {
        cursors.indices.contains(position) ? cursors[position] : nil
    }

    /// The position of the part before the current one, or `nil` if the current part is the first.
    private var previousCursor: BalladCursor? {
        cursors.indices.contains(position - 1) ? cursors[position - 1] : nil
    }

    mutating func next() -> BalladCursor? {
        guard position < cursors.endIndex else { return nil }
        position += 1
        return cursor
    }

    /// The current part, or `nil` if every part has been passed.
    var currentPart: Part? {
        guard let cursor else { return nil }
        return cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines[cursor.lineIndex].parts[cursor.partIndex]
    }

    /// The number of parts after the current one in the same line.
    var remainingParts: Int {
        guard let cursor else { return 0 }
        return cantos[cursor.cantoIndex].stanzas[cursor.stanzaIndex].lines[cursor.lineIndex].parts.endIndex - cursor.partIndex - 1
    }

    var isStartOfBallad: Bool {
        cursor != nil && previousCursor == nil
    }

    var isStartOfCanto: Bool {
        guard let cursor else { return false }
        guard let previousCursor else { return true }
        return previousCursor.cantoIndex != cursor.cantoIndex
    }

    var isStartOfStanza: Bool {
        guard let cursor else { return false }
        guard let previousCursor else { return true }
        return isStartOfCanto || previousCursor.stanzaIndex != cursor.stanzaIndex
    }

    var isStartOfLine: Bool {
        guard let cursor else { return false }
        guard let previousCursor else { return true }
        return isStartOfStanza || previousCursor.lineIndex != cursor.lineIndex
    }
}
