//
//  RomanNumeralsTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Testing
@testable import ConnaughtSquare

/// Note that `romanNumeral(for:)` traps for numbers outside 1...3999, so only the valid range is covered.
struct RomanNumeralsTests {

    @Test(arguments: [
        (1, "I"), (2, "II"), (3, "III"), (5, "V"), (6, "VI"), (10, "X"),
        (11, "XI"), (50, "L"), (100, "C"), (500, "D"), (1000, "M")
    ])
    func testAdditiveNotation(number: Int, expected: String) {
        #expect(romanNumeral(for: number) == expected)
    }

    @Test(arguments: [
        (4, "IV"), (9, "IX"), (40, "XL"), (90, "XC"), (400, "CD"), (900, "CM")
    ])
    func testSubtractiveNotation(number: Int, expected: String) {
        #expect(romanNumeral(for: number) == expected)
    }

    @Test(arguments: [
        (14, "XIV"), (49, "XLIX"), (1990, "MCMXC"), (2024, "MMXXIV")
    ])
    func testCombinedNotation(number: Int, expected: String) {
        #expect(romanNumeral(for: number) == expected)
    }

    @Test func testBoundsOfTheValidRange() {
        #expect(romanNumeral(for: 1) == "I")
        #expect(romanNumeral(for: 3999) == "MMMCMXCIX")
    }

    /// A canto title uses the numeral, so every canto number a ballad can produce must convert.
    @Test func testEveryNumeralIsNonEmpty() {
        for number in 1...3999 {
            #expect(romanNumeral(for: number).isEmpty == false)
        }
    }
}
