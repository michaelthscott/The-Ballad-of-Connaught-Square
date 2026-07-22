//
//  LineTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Foundation
import Testing
import NaturalLanguage
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
@testable import ConnaughtSquare

// TODO: Redo these tests so that they don't require tag parsing in Line().

final class LineTests {
    func line(_ speakers: String...) -> Line {
        var parts: [Part] = []
        var strings: [String] = []
        for speaker in speakers.indices {
            parts.append(Part(speaker: Int(speaker), string: speakers[speaker]))
            strings.append(speakers[speaker])
        }
		return Line(parts: parts)
    }
    
    @Test func testEquatable() {
        #expect(line("Cow") == line("Cow"))
    }
    
    @Test func testComparable() {
        #expect(line("Cow") < line("Milking"))
    }
    
    @Test func testStartsWith() {
        #expect(line("Cow", "Milking").startsWith(tag: .noun))
    }
    
    @Test func testEndsWith() {
        #expect(line("Good morning").endsWith(rhyme: Rhyme(phonemes: [Phoneme(sound: .IH, stress: .noStress), Phoneme(sound: .NG)])))
    }
    
    @Test func testPList() {
        let resource = "LineTest"
        guard let asset = NSDataAsset(name: resource, bundle: Bundle(for: Self.self)) else {
            Issue.record("failed to find \(resource)")
            return
        }
        let decoder = PropertyListDecoder()
        do {
            let line = try decoder.decode(Line.self, from: asset.data)
            // Update if plist changes.
            #expect(line.parts.count == 2)
            #expect(line.string == "Won't get me out. You don't drink, you're a weirdo.")
        } catch let error {
            Issue.record("failed to read \(resource): \(error)")
        }
    }
    
    @Test func testLineTags() {
        #expect(line("The cat sat on the mat.").tags == [.determiner, .noun, .verb, .preposition, .determiner, .noun])
        #expect(line("How is the brown horse?").tags == [.pronoun, .verb, .determiner, .adjective, .noun])
        #expect(line("Mike likes coffee.").tags == [.personalName, .verb, .noun])
    }
    
    @Test func testLastWord() {
        guard let last = line("I liked him, he was.", "He is isn't he, he's over thirty.").lastWord else {
            Issue.record("Failed to get last word.")
            return
        }
        #expect(last.string == "THIRTY")
    }
    
    @Test func testRhymesWith() {
        #expect(line("I liked him, he was.", "Yeah, we do.").rhymesWith(line: line("I liked him, he was.", "Four nine six two two.")))
    }
    
    @Test func testCodable() {
        let line = line("I liked him, he was.", "Yeah, we do.")
        let encoder = PropertyListEncoder()
        guard let data = try? encoder.encode(line) else {
            Issue.record("Failed to encode")
            return
        }
        let decoder = PropertyListDecoder()
        guard let copy = try? decoder.decode(Line.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }
        #expect(line == copy)
    }
	
    @Test func testRecitedParts() {
		let line = line("I liked him, he was.", "Yeah, we do.")
        #expect(line.parts.count == 2)
        #expect(line.recitedParts.count == 0)
		line.parts[0].isRecited = true
        #expect(line.recitedParts.count == 1)
		line.parts[1].isRecited = true
        #expect(line.recitedParts.count == 2)
	}
	
    @Test func testIsRecited() {
		let line = line("I liked him, he was.", "Yeah, we do.")
        #expect(line.isRecited == false)
		line.isRecited = true
        #expect(line.isRecited)
		line.isRecited = false
        #expect(line.isRecited == false)
	}
}
