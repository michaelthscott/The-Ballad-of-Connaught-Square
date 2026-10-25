//
//  StringExtensionsTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Foundation
import Testing
@testable import ConnaughtSquare

struct StringExtensionsTests {

    @Test func testWords() {
        #expect("The cat sat".words == ["The", "cat", "sat"])
    }

    @Test func testWordsKeepPunctuation() {
        #expect("Won't get me out.".words == ["Won't", "get", "me", "out."])
    }

    @Test func testWordCount() {
        #expect("The cat sat on the mat.".wordCount == 6)
    }

    @Test func testEmptyStringHasNoWords() {
        #expect("".words == [])
        #expect("".wordCount == 0)
        #expect("".speakingTime == .zero)
    }

    @Test func testRepeatedWhitespaceSeparatesOnce() {
        #expect("  ".wordCount == 0)
        #expect("The  cat".words == ["The", "cat"])
        #expect("  The cat  ".words == ["The", "cat"])
    }

    @Test func testNewlinesAndTabsSeparateWords() {
        #expect("The\ncat\tsat".words == ["The", "cat", "sat"])
    }

    /// Speech is estimated at 183 words per minute, so 61 words take 20 seconds.
    @Test func testSpeakingTime() {
        let sentence = Array(repeating: "word", count: 61).joined(separator: " ")
        #expect(sentence.speakingTime == .seconds(20))
    }

    @Test func testSpeakingTimeIsProportionalToWordCount() {
        let short = Array(repeating: "word", count: 61).joined(separator: " ")
        let long = Array(repeating: "word", count: 122).joined(separator: " ")
        #expect(long.speakingTime == short.speakingTime * 2)
    }

    @Test func testSpeakingTimeOfASingleWordIsNonZero() {
        #expect("word".speakingTime > .zero)
    }
}
