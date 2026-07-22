//
//  CantoTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Testing
@testable import ConnaughtSquare

final class CantoTests {
	var canto: Canto!
	
	init() {
		let tagger = LinguisticTagger()
		let string1 = "The number one."
		let string2 = "The number two."
		let part1 = Part(speaker: 0, string: string1)
		let part2 = Part(speaker: 1, string: string2)
		let lineString1 = "\(string1) \(string2)"
		let lineString2 = "\(string2) \(string1)"
		let line1 = Line(parts: [part1, part2], string: lineString1, tags: tagger.linguisticTagsArray(string: lineString1))
		let line2 = Line(parts: [part1, part2], string: lineString2, tags: tagger.linguisticTagsArray(string: lineString2))
		let lines1 = [line1, line2]
		let lines2 = [line2, line1]
		let stanzas = [Stanza(lines: lines1[...]), Stanza(lines: lines2[...])]
		canto = Canto(tag: .determiner, stanzas: stanzas, number: 1)
	}

	deinit {
		canto = nil
	}

    @Test func testInit() {
        #expect(canto.title == "Canto I")
        #expect(canto.stanzas.count == 2)
    }
	
    @Test func testIsRecited() {
        #expect(canto.isRecited == false)
		canto.isRecited = true
        #expect(canto.isRecited)
		canto.isRecited = false
        #expect(canto.isRecited == false)
	}
	
    @Test func testRecitedStanzas() {
		canto.isRecited = false
        #expect(canto.recitedStanzas.count == 0)
		canto.isRecited = true
        #expect(canto.recitedStanzas.count == canto.stanzas.count)
	}
}
