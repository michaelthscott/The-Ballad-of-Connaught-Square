//
//  TestBallad.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 10/11/2026.
//

import Foundation
@testable import ConnaughtSquare

extension Ballad {
    /// A ballad of one canto, one stanza, two lines and, by default, three parts.
    ///
    /// Both lines start with a determiner so that they are gathered into a canto. The tags are given
    /// rather than found by `LinguisticTagger`, as the lexical class model isn't available on every
    /// run destination.
    static func test(partsInFirstLine: Int = 2) -> Ballad {
        let firstLine = Line(parts: (0..<partsInFirstLine).map {
            Part(string: "The cat sat on mat number \($0).")
        }, tags: [.determiner])
        let secondLine = Line(parts: [Part(string: "The dog barked loudly.")], tags: [.determiner])
        return Ballad(lines: [firstLine, secondLine],
                      tags: LinguisticTagOrder(tags: [.determiner(weight: 1)]))
    }
}
