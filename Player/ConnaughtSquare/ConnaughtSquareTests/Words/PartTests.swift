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
        let part = Part(string: "")
        #expect(part.string == "")
    }
    
    @Test func testEquatable() {
        let part1 = Part(string: "")
        let part2 = Part(string: "")
        let part3 = Part(string: "x")
        #expect(part1 == part2)
        #expect(part1 != part3)
    }
    
    @Test func testAssetWithoutPronunciations() {
        let resource = "Part-without-pronunciations"
        guard let asset = NSDataAsset(name: "\(resource)", bundle: Bundle(for: Self.self)) else {
            Issue.record("failed to find \(resource)")
            return
        }
        let decoder = JSONDecoder()
        do {
            let part = try decoder.decode(Part.self, from: asset.data)
            // Update if the asset changes.
            let string = "Keeping records."
            #expect(part.string == string)
            #expect(part.nsAttributedString.string == string)
        } catch let error {
            Issue.record("failed to read \(resource): \(error)")
        }
    }
    
    @Test func testAsset() {
        let resource = "Part"
        guard let asset = NSDataAsset(name: "\(resource)", bundle: Bundle(for: Self.self)) else {
            Issue.record("failed to find \(resource)")
            return
        }
        let decoder = JSONDecoder()
        do {
            let part = try decoder.decode(Part.self, from: asset.data)
            // Update if the asset changes.
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
        
        let part = Part(string: "Keeping records.", pronunciations: [
            CorrectPronunciation(ipa: "ˈkiːpɪŋ", location: 0, length: 7),
            CorrectPronunciation(ipa: "ˈɻɛ.ˈkɔɻts", location: 8, length: 7)])
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(part) else {
            Issue.record("Failed to encode")
            return
        }
        let decoder = JSONDecoder()
        guard let copy = try? decoder.decode(Part.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }
        #expect(part == copy)
        #expect(copy.pronunciations == part.pronunciations)
    }

    @Test func testDuration() {
		let words = Lexicon.shared.words
		let text = words[0..<183].map({ $0.string }).joined(separator: " ")
		let part = Part(string: text)
		let seconds = part.duration.components.seconds
		print(part.duration.components.seconds)
        #expect(seconds == 60)
	}
}
