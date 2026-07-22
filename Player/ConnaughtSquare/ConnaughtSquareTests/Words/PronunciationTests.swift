//
//  PronunciationTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 08/10/2023.
//

import Testing
import NaturalLanguage
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
@testable import ConnaughtSquare

// TODO: Convert these tests to use words from the lexicon.

final class PronunciationTests {
	var lexicon: Lexicon!
	
	init() throws {
		lexicon = Lexicon.shared
	}
	
	deinit {
		lexicon = nil
	}
	
    @Test func testDescription() {
        #expect(lexicon.word("AGREEMENTS")?.pronunciation.description == "[AH0, G, R, IY1, M, AH0, N, T, S]")
    }
    
    @Test func testEncode() {
        let p = Pronunciation(phonemes: [Phoneme(sound: .AA, stress: .primaryStress), Phoneme(sound: .CH)])
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let data = try encoder.encode(p)
            #expect(data.count == 397)
        } catch {
            Issue.record("failed to encode: \(error)")
        }
    }
    
    @Test func testDecode() {
        let resource = "Pronunciation"
        guard let asset = NSDataAsset(name: "\(resource)", bundle: Bundle(for: Self.self)) else {
            Issue.record("failed to find \(resource)")
            return
        }
        let decoder = PropertyListDecoder()
        do {
            let pronuciation = try decoder.decode(Pronunciation.self, from: asset.data)
            // Update if plist changes.
            #expect(pronuciation.phonemes.count == 8)
            if let first = pronuciation.phonemes.first {
                #expect(first.sound == .IH)
                #expect(first.stress == .primaryStress)
            } else {
                Issue.record("failed to get first phoneme")
            }
            if let last = pronuciation.phonemes.last {
                #expect(last.sound == .Z)
            } else {
                Issue.record("failed to get last phoneme")
            }
        } catch {
            Issue.record("failed to read \(resource): \(error)")
        }
    }

    @Test func testEquatable() {
        let p1 = Pronunciation(phonemes: [Phoneme(sound: .AA, stress: .primaryStress)])
        let p2 = Pronunciation(phonemes: [Phoneme(sound: .CH)])
        #expect(p1 == p1)
        #expect(p2 == p2)
        #expect(p1 != p2)
    }

    // TODO: Need to test word with longer sequences of vowels and consonants.
                
    @Test func testIsLegalOnset() {
        let array = [Phoneme(sound: .B), Phoneme(sound: .L), Phoneme(sound: .W)]
        #expect(array[...].isLegalOnset())
    }
    
    @Test func testCodable() {
        let pronunciation = Pronunciation(phonemes: [Phoneme(sound: .S), Phoneme(sound: .L), Phoneme(sound: .IY, stress: .primaryStress), Phoneme(sound: .P)])
        let encoder = PropertyListEncoder()
        guard let data = try? encoder.encode(pronunciation) else {
            Issue.record("Failed to encode")
            return
        }
        let decoder = PropertyListDecoder()
        guard let copy = try? decoder.decode(Pronunciation.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }
        #expect(pronunciation == copy)
    }
	
    @Test func testSyllableSegments() {
		var word: Word
		word = lexicon.word("EVENTUALLY")!
        #expect("\(word.pronunciation.syllableSegments)" == "[N[IH0], O[V], N[EH1], C[N], O[CH], N[AH0], O[W], N[AH0], O[L], N[IY0]]")
		word = lexicon.word("EXCEPTIONALLY")!
        #expect("\(word.pronunciation.syllableSegments)" == "[N[IH0], C[K], O[S], N[EH1], O[P, SH], N[AH0], O[N], N[AH0], O[L], N[IY0]]")
		word = lexicon.word("INVESTIGATING")!
        #expect("\(word.pronunciation.syllableSegments)" == "[N[IH2], C[N], O[V], N[EH1], O[S, T], N[AH0], O[G], N[EY2], O[T], N[IH0], C[NG]]")
		word = lexicon.word("INVESTIGATOR")!
        #expect("\(word.pronunciation.syllableSegments)" == "[N[IH2], C[N], O[V], N[EH1], O[S, T], N[AH0], O[G], N[EY2], O[T], N[ER0]]")
		word = lexicon.word("OCCASIONALLY")!
        #expect("\(word.pronunciation.syllableSegments)" == "[N[AO0], O[K], N[EY1], O[ZH], N[AH0], O[N], N[AH0], O[L], N[IY2]]")
		word = lexicon.word("UNFORTUNATELY")!
        #expect("\(word.pronunciation.syllableSegments)" == "[N[AH0], C[N], O[F], N[AO1], C[R], O[CH], N[AH0], O[N], N[AH0], O[T, L], N[IY0]]")
	}
	
    @Test func testSyllables() {
		var word: Word
		word = lexicon.word("EVENTUALLY")!
        #expect("\(word.pronunciation.syllables)" == "[IH0, V-EH1-N, CH-AH0, W-AH0, L-IY0]")
		word = lexicon.word("EXCEPTIONALLY")!
        #expect("\(word.pronunciation.syllables)" == "[IH0-K, S-EH1, PSH-AH0, N-AH0, L-IY0]")
		word = lexicon.word("INVESTIGATING")!
        #expect("\(word.pronunciation.syllables)" == "[IH2-N, V-EH1, ST-AH0, G-EY2, T-IH0-NG]")
		word = lexicon.word("INVESTIGATOR")!
        #expect("\(word.pronunciation.syllables)" == "[IH2-N, V-EH1, ST-AH0, G-EY2, T-ER0]")
		word = lexicon.word("OCCASIONALLY")!
        #expect("\(word.pronunciation.syllables)" == "[AO0, K-EY1, ZH-AH0, N-AH0, L-IY2]")
		word = lexicon.word("UNFORTUNATELY")!
        #expect("\(word.pronunciation.syllables)" == "[AH0-N, F-AO1-R, CH-AH0, N-AH0, TL-IY0]")
	}
}

