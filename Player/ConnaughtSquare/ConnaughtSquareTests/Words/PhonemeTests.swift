//
//  PhonemeTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Testing
import NaturalLanguage
@testable import ConnaughtSquare

struct PhonemeTests {
    
    @Test func testEquatable() {
        let aa1 = Phoneme(sound: .AA, stress: .primaryStress)
        let aa2 = Phoneme(sound: .AA, stress: .primaryStress)
        let aa3 = Phoneme(sound: .AA, stress: .secondaryStress)
        let b = Phoneme(sound: .B, stress: nil)
        #expect(aa1 == aa2)
        #expect(aa1 != aa3)
        #expect(aa1 != b)
    }

    @Test func testStress() {
        let consonant = Phoneme(sound: .B, stress: .primaryStress)
        #expect(consonant.stress == nil)
    }
    
    @Test func testDescription() {
        let aa1 = Phoneme(sound: .AA, stress: .primaryStress)
        #expect(aa1.description == "AA1")
    }
    
    @Test func testIPA() {
        let jh = Phoneme(sound: .JH)
        #expect(jh.ipa == "ʤ")
    }
    
    @Test func testCodable() {
        let phoneme = Phoneme(sound: .AA, stress: .primaryStress)
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(phoneme) else {
            Issue.record("Failed to encode")
            return
        }
        let decoder = JSONDecoder()
        guard let copy = try? decoder.decode(Phoneme.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }
        #expect(phoneme == copy)
    }

    /// Phonemes are written in cmudict's notation, with a vowel's stress as a digit after its sound.
    @Test(arguments: [
        ("AH0", Phoneme(sound: .AH, stress: .noStress)),
        ("AA1", Phoneme(sound: .AA, stress: .primaryStress)),
        ("EY2", Phoneme(sound: .EY, stress: .secondaryStress)),
        ("ER", Phoneme(sound: .ER)),
        ("CH", Phoneme(sound: .CH)),
    ])
    func testNotation(notation: String, phoneme: Phoneme) throws {
        #expect(Phoneme(notation: notation) == phoneme)
        #expect(String(decoding: try JSONEncoder().encode(phoneme), as: UTF8.self) == "\"\(notation)\"")
        #expect(try JSONDecoder().decode(Phoneme.self, from: Data("\"\(notation)\"".utf8)) == phoneme)
    }

    /// A stressed consonant, an unknown sound or an unknown stress isn't a phoneme.
    @Test(arguments: ["CH1", "XX", "AA9", "aa1", "", "1"])
    func testInvalidNotation(notation: String) {
        #expect(Phoneme(notation: notation) == nil)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Phoneme.self, from: Data("\"\(notation)\"".utf8))
        }
    }
}
