//
//  NoteVelocity.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 07/12/2023.
//
 
import Foundation
import GameplayKit



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
    static func gaussianRandom() -> NoteVelocity {
        let generator = GKGaussianDistribution(randomSource: GKRandomSource(), lowestValue: 0, highestValue: 9)
        let index = generator.nextInt()
        return allCases[index]
    }
    
    static func random<T: RandomNumberGenerator>(using generator: inout T) -> NoteVelocity {
        guard let random = allCases.randomElement() else {
            return .mp
        }
        return random
    }

    static func random() -> NoteVelocity {
        var rng = SystemRandomNumberGenerator()
        return NoteVelocity.random(using: &rng)
    }
}
