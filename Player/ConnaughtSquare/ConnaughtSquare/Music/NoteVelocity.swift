//
//  NoteVelocity.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 07/12/2023.
//
 
import Foundation

/// Note velocities in in standard musical terminology.
enum NoteVelocity: UInt8, CaseIterable {
    case pppp = 10
    case ppp = 23
    case pp = 36
    case p = 49
    case mp = 62
    case mf = 75
    case f = 88
    case ff = 101
    case fff = 114
    case ffff = 127
}

extension NoteVelocity {
    /// The MIDI velocity at the volume, from silent at 0 to the velocity itself at 1.
    /// - Parameter volume: A volume between 0 and 1. Volumes outside that range are clamped to it.
    /// - Returns: The scaled velocity, which is 0 only when the note shouldn't sound.
    func scaled(by volume: Double) -> UInt8 {
        let clamped = min(max(volume, 0), 1)
        return UInt8((Double(rawValue) * clamped).rounded())
    }

    /// Selects a velocity from a normal distribution centred on the middle velocities, so moderate dynamics are the most likely and the extremes rare.
    ///
    /// The distribution is over the indices of `allCases`, with a mean halfway between the first and last and a standard deviation of a sixth of the range,
    /// as GameplayKit's `GKGaussianDistribution` uses. Samples that fall outside the range are drawn again.
    /// - Parameter generator: The random number generator to use.
    /// - Returns: The velocity.
    static func gaussianRandom<T: RandomNumberGenerator>(using generator: inout T) -> NoteVelocity {
        let highest = Double(allCases.count - 1)
        let mean = highest / 2
        let deviation = highest / 6
        while true {
            // The Box–Muller transform turns two uniform samples into a standard normal sample.
            // The first sample must be positive so that its logarithm is defined.
            let u1 = Double.random(in: Double.leastNonzeroMagnitude...1, using: &generator)
            let u2 = Double.random(in: 0..<1, using: &generator)
            let z = (-2 * log(u1)).squareRoot() * cos(2 * Double.pi * u2)
            let index = (mean + z * deviation).rounded()
            if (0...highest).contains(index) {
                return allCases[Int(index)]
            }
        }
    }

    /// Selects a velocity from a normal distribution centred on the middle velocities, using the system's random number generator.
    /// - Returns: The velocity.
    static func gaussianRandom() -> NoteVelocity {
        var generator = SystemRandomNumberGenerator()
        return gaussianRandom(using: &generator)
    }

    static func random<T: RandomNumberGenerator>(using generator: inout T) -> NoteVelocity {
        guard let random = allCases.randomElement(using: &generator) else {
            return .mp
        }
        return random
    }

    static func random() -> NoteVelocity {
        var rng = SystemRandomNumberGenerator()
        return NoteVelocity.random(using: &rng)
    }
}
