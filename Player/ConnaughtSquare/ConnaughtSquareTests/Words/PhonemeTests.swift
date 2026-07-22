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
        let encoder = PropertyListEncoder()
        guard let data = try? encoder.encode(phoneme) else {
            Issue.record("Failed to encode")
            return
        }
        let decoder = PropertyListDecoder()
        guard let copy = try? decoder.decode(Phoneme.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }
        #expect(phoneme == copy)
    }
    
}
