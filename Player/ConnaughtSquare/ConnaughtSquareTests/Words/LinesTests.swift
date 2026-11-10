//
//  LinesTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 10/11/2026.
//

import Foundation
import Testing
@testable import ConnaughtSquare

/// Checks the ballad's lines asset, so that edits to its punctuation can't break the words.
final class LinesTests {
    var lines: [Line]!

    init() throws {
        lines = try decodeAsset("Lines", from: Bundle(for: Line.self))
    }

    deinit {
        lines = nil
    }

    /// Every punctuation mark is attached to a word. A free-standing mark at the end of a line would
    /// become its last word and break the rhyme, and anywhere else it would add to the speaking time.
    @Test func testPunctuationIsAttachedToWords() {
        let freeStanding = lines.flatMap { $0.parts }.filter { part in
            part.string.components(separatedBy: .whitespaces).contains { token in
                token.rangeOfCharacter(from: .alphanumerics) == nil
            }
        }
        #expect(freeStanding.map { $0.string } == [])
    }

    /// Breaking off, trailing off and hesitating are all marked with the single ellipsis character,
    /// which the voices respond to. Three full stops and dashes sound much like a full stop.
    @Test func testEllipsisIsTheOnlyMarkForBreakingOff() {
        let otherMarks = lines.flatMap { $0.parts }.filter { part in
            ["...", "—", "–"].contains { part.string.contains($0) }
        }
        #expect(otherMarks.map { $0.string } == [])
    }
}
