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
    
    init() {
		if let lines: [Line] = decodeAssets("LinesTest", from: Bundle(for: Self.self)),
		   let tags: LinguisticTagOrder = decodeAsset("TagsTest", from: Bundle(for: Self.self)) {
			ballad = Ballad(lines: lines, tags: tags)
		} else {
			ballad = Ballad()
		}
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
