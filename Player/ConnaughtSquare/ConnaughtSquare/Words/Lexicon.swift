//
//  Lexicon.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation

// Use the Lexicon tool to get approximate pronunciations for any new words.
// http://www.speech.cs.cmu.edu/tools/lextool.html

/// A lexicon is a collection of pronunciations for for words.
final class Lexicon {
    nonisolated(unsafe) static let shared = Lexicon(name: "Lexicon")
	private var wordsDict: [String: Word] = [:]
    
	init(words: [Word]) {
		for word in words {
			wordsDict[word.string] = word
		}
	}
	
	convenience init(name: String, bundle: Bundle? = nil) {
		guard let dict: [String: Pronunciation] = decodeAsset(name, from: bundle ?? Bundle(for: Self.self)) else {
			fatalError("Failed to parse \(name)")
		}
		var array: [Word] = []
		for (string, pronunciation) in dict {
			array.append(Word(string: string, pronunciation: pronunciation))
		}
		self.init(words: array)
    }
    
    /// A word that has a pronunciation in the lexicon.
    /// - Parameter string: The word to lookup in the lexicon.
    /// - Returns: The word if it is in the lexicon,
    func word(_ string: String) -> Word? {
        guard let word = wordsDict[string.uppercased()] else {
            return nil
        }
        return word
    }
    
    // TODO: legalOnsets().sorted(by: { return $0 < $1 })
    
    /// The Legality Principle is a language agnostic principle maintaining that syllable onsets and codas (the beginning and ends of syllables not including the vowel) are only legal if they are found as word onsets or codas in the language. The English word ‘’admit’’ must then be syllabified as ‘’ad-mit’’ since ‘’dm’’ is not found word-initially in the English language. This principle was first proposed in Daniel Kahn’s 1976 dissertation, ‘’Syllable-based generalizations in English phonology’’.
    var legalOnsets: Set<ArraySlice<Phoneme>> {
        var onsets: Set<ArraySlice<Phoneme>> = []
        for word in wordsDict.values {
			let onset = word.pronunciation.phonemes.prefix(while: {$0.isConsonant})
            if onset.count > 0 {
                onsets.insert(onset)
            }
        }
        return onsets
    }
    	
	/// The words in the lexicon.
	var words: [Word] {
		Array(wordsDict.values)
	}
	
	/// The words rhyming with the specified word.
	/// - Parameter word: The word to rhyme with.
	/// - Returns: The words which rhyme.
	func wordsRhyming(with word: Word) -> [Word] {
		wordsDict.values.filter({ $0.rhyme == word.rhyme }).filter({ $0 != word }).sorted()
	}
}

// These are used in the Rhymes playground.

extension Lexicon {
	func wordsWith(syllablesCount: Int) -> [Word] {
		words.filter({ word in
			word.pronunciation.syllables.count == syllablesCount
		}).sorted()
	}
	
	func wordsWith(syllable: (Word) -> StressedSyllable?) -> [Word] {
		var dict: Dictionary<StressedSyllable, [Word]> = [:]
		for word in words {
			guard let syllable = syllable(word) else { continue }
			dict[syllable, default: []].append(word)
		}
		return dict.filter({
			element in element.value.count > 1
		}).sorted(by: { lhs, rhs in
			lhs.value.count > rhs.value.count
		}).flatMap({ element in element.value }).sorted()
	}

//	func wordsWith(perfectRhyme: PerfectRhyme) -> Dictionary<StressedSyllable, [Word]> {
//		var dict: Dictionary<StressedSyllable, [Word]> = [:]
//		for word in words {
//			switch perfectRhyme {
//			case .single:
//				if let syllable = word.finalStressedSyllable {
//					dict[syllable, default: []].append(word)
//				}
//			case .double:
//				if let syllable = word.penultimateStressedSyllable {
//					dict[syllable, default: []].append(word)
//				}
//			case .dactylic:
//				if let syllable = word.antepenultimateStressedSyllable {
//					dict[syllable, default: []].append(word)
//				}
//			}
//		}
//		return dict.filter({
//			element in element.value.count > 1
//		})
//	}
}
