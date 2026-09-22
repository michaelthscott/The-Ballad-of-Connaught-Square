//
//  CorrectPronunciationTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Foundation
import AVFoundation
import Testing
@testable import ConnaughtSquare

struct CorrectPronunciationTests {
    let connaught = CorrectPronunciation(ipa: "kɒnɔːt", location: 4, length: 9)

    @Test func testEquatable() {
        #expect(connaught == CorrectPronunciation(ipa: "kɒnɔːt", location: 4, length: 9))
        #expect(connaught != CorrectPronunciation(ipa: "kɒnɔːt", location: 0, length: 9))
        #expect(connaught != CorrectPronunciation(ipa: "kɒnɔːt", location: 4, length: 4))
        #expect(connaught != CorrectPronunciation(ipa: "kɒnɔt", location: 4, length: 9))
    }

    /// Pronunciations are archived with the parts of a line, so they have to survive a round trip.
    @Test func testCodable() throws {
        let data = try PropertyListEncoder().encode([connaught])
        let copy = try PropertyListDecoder().decode([CorrectPronunciation].self, from: data)
        #expect(copy == [connaught])
    }

    /// The location and length address a range of the part's string, and are applied as written.
    @Test func testAppliedToAPart() {
        let part = Part(speaker: 0, string: "The Connaught Square", pronunciations: [connaught])
        let key = NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute)
        let range = NSRange(location: 0, length: part.nsAttributedString.length)
        var found: [String] = []
        part.nsAttributedString.enumerateAttribute(key, in: range) { value, _, _ in
            if let ipa = value as? String {
                found.append(ipa)
            }
        }
        #expect(found == ["kɒnɔːt"])
    }
}
