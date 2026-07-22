//
//  StanzaTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Foundation
import Testing
@testable import ConnaughtSquare

final class StanzaTests {
	var stanza: Stanza!
    
    init() {
		if let lines: [Line] = decodeAssets("LinesTest", from: Bundle(for: Self.self)) {
			stanza = Stanza(lines: lines[...])
		} else {
			stanza = Stanza(lines: [])
		}
    }

    deinit {
		stanza = nil
    }

    @Test func testInit() {
        #expect(stanza.lines.count == 10)
    }

    @Test func testStartsWith() {
		let tag: LinguisticTag = .pronoun
        #expect(stanza.startsWith(tag: tag))
    }
	
    @Test func testRecitedLines() {
        #expect(stanza.recitedLines.count == 0)
		stanza.lines[0].parts[0].isRecited = true
        #expect(stanza.recitedLines.count == 1)
	}
	
    @Test func testIsRecited() {
        #expect(stanza.isRecited == false)
		stanza.isRecited = true
        #expect(stanza.isRecited)
		stanza.isRecited = false
        #expect(stanza.isRecited == false)
	}
}
