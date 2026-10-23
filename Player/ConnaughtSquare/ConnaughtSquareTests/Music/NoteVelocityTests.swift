//
//  NoteVelocityTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/02/2024.
//

import Testing
@testable import ConnaughtSquare

struct NoteVelocityTests {

    @Test func testNoteVelocity() async throws {
        #expect(NoteVelocity.random().rawValue != 0)
    }

    @Test func testGaussianRandomFavoursTheMiddle() {
        var generator = SeededRandomNumberGenerator(seed: 7)
        var counts: [NoteVelocity: Int] = [:]
        for _ in 0..<10_000 {
            counts[NoteVelocity.gaussianRandom(using: &generator), default: 0] += 1
        }
        // With a mean of 4.5 and a deviation of 1.5, about a quarter of draws land on each of mp and mf, and well under 1% on each extreme.
        #expect((2200...2800).contains(counts[.mp] ?? 0))
        #expect((2200...2800).contains(counts[.mf] ?? 0))
        #expect((counts[.pppp] ?? 0) < 100)
        #expect((counts[.ffff] ?? 0) < 100)
        #expect(counts.values.reduce(0, +) == 10_000)
    }

    @Test func testGaussianRandomIsRepeatableWithASeed() {
        var first = SeededRandomNumberGenerator(seed: 42)
        var second = SeededRandomNumberGenerator(seed: 42)
        let a = (0..<20).map { _ in NoteVelocity.gaussianRandom(using: &first) }
        let b = (0..<20).map { _ in NoteVelocity.gaussianRandom(using: &second) }
        #expect(a == b)
    }

    @Test func testRandomUsesTheGivenGenerator() {
        var first = SeededRandomNumberGenerator(seed: 42)
        var second = SeededRandomNumberGenerator(seed: 42)
        let a = (0..<20).map { _ in NoteVelocity.random(using: &first) }
        let b = (0..<20).map { _ in NoteVelocity.random(using: &second) }
        #expect(a == b)
    }

}
