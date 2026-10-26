//
//  BalladTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Foundation
import Testing
@testable import ConnaughtSquare

final class BalladTests {
    var ballad: Ballad!
    
    init() throws {
		let lines: [Line] = try decodeAsset("LinesTest", from: Bundle(for: Self.self))
		let tags: LinguisticTagOrder = try decodeAsset("TagsTest", from: Bundle(for: Self.self))
		ballad = Ballad(lines: lines, tags: tags)
     }

    deinit {
        ballad = nil
    }
    
    @Test func testInit() {
        #expect(ballad.lines.count == 10)
    }
        
    // TODO: This depends on the tag order. Parts are defined by the first tag in the stanza.
    @Test func testParts() {
        #expect(ballad.cantos.count > 0)
    }

    /// Every part is in a canto, even when the ballad's tag order doesn't hold the tag a stanza starts with.
    @Test(.enabled(if: LinguisticTagger().isTagSchemeAvailable)) func testCantosHoldEveryStanza() throws {
        func line(_ string: String) throws -> Line {
            try Line(parts: [Part(speaker: 0, string: string)])
        }
        // Lines without tags count as other words.
        let lines = [try line("Run home now."), try line("The cat sat."), try line("Go on."), try line("A dog ran."), try line("...")]
        #expect(lines.last?.tags.isEmpty == true)
        for tags in [LinguisticTagOrder(tags: []), LinguisticTagOrder(tags: [.determiner(weight: 1)])] {
            let ballad = Ballad(lines: lines, tags: tags)
            #expect(ballad.cantos.flatMap { $0.stanzas }.count == 2)
            #expect(ballad.parts.count == lines.count)
            // The cantos are numbered in turn, including those for tags missing from the order.
            #expect(ballad.cantos.map { $0.title } == ballad.cantos.indices.map { "Canto \(romanNumeral(for: $0 + 1))" })
        }
    }
        
    @Test func testIsRecited() {
        #expect(ballad.isRecited == false)
		ballad.isRecited = true
        #expect(ballad.isRecited)
		ballad.isRecited = false
        #expect(ballad.isRecited == false)
	}
	
    @Test func testRecitedCantos() {
        #expect(ballad.cantos.count != ballad.recitedCantos.count)
		ballad.isRecited = true
        #expect(ballad.cantos.count == ballad.recitedCantos.count)
		ballad.isRecited = false
        #expect(ballad.cantos.count != ballad.recitedCantos.count)
	}
}
