//
//  AnyRandomNumberGenerator.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 10/11/2026.
//

/// A random number generator of any kind, as a concrete type that can be passed `inout` to
/// functions generic over their generator.
struct AnyRandomNumberGenerator: RandomNumberGenerator {
    private var base: any RandomNumberGenerator

    init(_ base: any RandomNumberGenerator) {
        self.base = base
    }

    mutating func next() -> UInt64 {
        base.next()
    }
}
