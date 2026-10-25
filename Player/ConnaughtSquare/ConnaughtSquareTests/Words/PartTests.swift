//
//  PartTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Testing
import AVFoundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
@testable import ConnaughtSquare

final class PartTests {
    
    @Test func testInit() {
        let part = Part(speaker: 0, string: "")
        #expect(part.string == "")
    }
    
    @Test func testEquatable() {
        let part1 = Part(speaker: 0, string: "")
        let part2 = Part(speaker: 0, string: "")
        let part3 = Part(speaker: 0, string: "x")
        let part4 = Part(speaker: 1, string: "x")
        #expect(part1 == part2)
        #expect(part1 != part3)
        #expect(part3 != part4)
    }
    
    @Test func testPListWithoutPronunciations() {
        let resource = "Part-without-pronunciations"
        guard let asset = NSDataAsset(name: "\(resource)", bundle: Bundle(for: Self.self)) else {
            Issue.record("failed to find \(resource)")
            return
        }
        let decoder = PropertyListDecoder()
        do {
            let part = try decoder.decode(Part.self, from: asset.data)
            // Update if plist changes.
            let string = "Keeping records."
            #expect(part.string == string)
            #expect(part.nsAttributedString.string == string)
        } catch let error {
            Issue.record("failed to read \(resource): \(error)")
        }
    }
    
    @Test func testPList() {
        let resource = "Part"
        guard let asset = NSDataAsset(name: "\(resource)", bundle: Bundle(for: Self.self)) else {
            Issue.record("failed to find \(resource)")
            return
        }
        let decoder = PropertyListDecoder()
        do {
            let part = try decoder.decode(Part.self, from: asset.data)
            // Update if plist changes.
            let string = "Keeping records."
            #expect(part.string == string)
            #expect(part.pronunciations == [
                CorrectPronunciation(ipa: "ˈkiːpɪŋ", location: 0, length: 7),
                CorrectPronunciation(ipa: "ˈɻɛ.ˈkɔɻts", location: 8, length: 7)])
        } catch let error {
            Issue.record("failed to read \(resource): \(error)")
        }
    }
        
    @Test func testCodable() {
        
        let part = Part(speaker: 0, string: "Keeping records.", pronunciations: [
            CorrectPronunciation(ipa: "ˈkiːpɪŋ", location: 0, length: 7),
            CorrectPronunciation(ipa: "ˈɻɛ.ˈkɔɻts", location: 8, length: 7)])
        let encoder = PropertyListEncoder()
        guard let data = try? encoder.encode(part) else {
            Issue.record("Failed to encode")
            return
        }
        let decoder = PropertyListDecoder()
        guard let copy = try? decoder.decode(Part.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }
        #expect(part == copy)
        #expect(copy.pronunciations == part.pronunciations)

//        print("nsAttributedString = \(part.nsAttributedString)")
//        print("attributedString = \(part.attributedString)")
    }
	
    /// The pronunciation is applied at its location, not to the first occurrence of the same text.
    @Test func testAttributedStringMarksTheLocatedOccurrence() {
        let part = Part(speaker: 0, string: "read and read", pronunciations: [
            CorrectPronunciation(ipa: "ɹɛd", location: 9, length: 4)])
        let attributedString = part.attributedString
        let marked = attributedString.runs.compactMap { run in
            run.accessibilitySpeechPhoneticNotation.map { (String(attributedString[run.range].characters), $0) }
        }
        #expect(marked.count == 1)
        #expect(marked.first?.0 == "read")
        #expect(marked.first?.1 == "ɹɛd")
        #expect(attributedString.runs.first?.accessibilitySpeechPhoneticNotation == nil)
    }

    /// A pronunciation outside the string is ignored rather than discarding the string.
    @Test func testAttributedStringIgnoresAPronunciationOutsideTheString() {
        let part = Part(speaker: 0, string: "Woah.", pronunciations: [
            CorrectPronunciation(ipa: "wəʊ", location: 3, length: 10)])
        let attributedString = part.attributedString
        #expect(String(attributedString.characters) == "Woah.")
        #expect(attributedString.runs.allSatisfy { $0.accessibilitySpeechPhoneticNotation == nil })
    }

    @Test func testDuration() {
		let words = Lexicon.shared.words
		let text = words[0..<183].map({ $0.string }).joined(separator: " ")
		let part = Part(speaker: 0, string: text)
		let seconds = part.duration.components.seconds
		print(part.duration.components.seconds)
        #expect(seconds == 60)
	}
}
