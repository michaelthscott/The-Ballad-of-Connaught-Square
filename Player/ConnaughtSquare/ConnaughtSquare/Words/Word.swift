//
//  Word.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation
import Accessibility

/// A word is a unit of speech.
final class Word {
	let string: String
    let pronunciation: Pronunciation
    
	init(string: String, pronunciation: Pronunciation) {
		self.string = string
		self.pronunciation = pronunciation
	}
	
    var syllables: [Syllable] {
		pronunciation.syllables
    }
    
    /// The last syllable.
    var rhyme: Rhyme? {
        guard let last = syllables.last else { return nil }
        return last.rhyme
    }
	
	var finalSyllable: Syllable? {
		guard let syllable = syllables.last else { return nil }
		return syllable
	}
	
	var penultimateSyllable: Syllable? {
		guard let syllable = syllables.penultimate else { return nil }
		return syllable
	}
	
	var antepenultimateSyllable: Syllable? {
		guard let syllable = syllables.antepenultimate else { return nil }
		return syllable
	}
	
	/// The final syllable if it is stressed. This is used for a single, also known as masculine rhyme.
	var finalStressedSyllable: StressedSyllable? {
		guard let syllable = finalSyllable else { return nil }
		return syllable.isStressed ? .final(syllable) : nil
	}
	
	/// The penultimate (second from last) syllable, if it is stressed. This is used for a double, also known as feminine rhyme.
	var penultimateStressedSyllable: StressedSyllable? {
		guard let syllable = penultimateSyllable else { return nil }
		return syllable.isStressed ? .penultimate(syllable) : nil
	}
	
	/// The antepenultimate (third from last) syllable, if it is stressed. This is used for a dactylic rhyme.
	var antepenultimateStressedSyllable: StressedSyllable? {
		guard let syllable = antepenultimateSyllable else { return nil }
		return syllable.isStressed ? .antepenultimate(syllable) : nil
	}
	
	var vowels: [Phoneme] {
		pronunciation.phonemes.filter { $0.isVowel }
	}
	
	var consonants: [Phoneme] {
		pronunciation.phonemes.filter { $0.isConsonant }
	}
}

extension Word: Equatable {
	static func == (lhs: Word, rhs: Word) -> Bool {
		lhs.string.uppercased() == rhs.string.uppercased()
	}
}

extension Word: Comparable {
	static func < (lhs: Word, rhs: Word) -> Bool {
		lhs.string.uppercased() < rhs.string.uppercased()
	}
}

extension Word: CustomStringConvertible {
	var description: String {
		string
	}
}

fileprivate extension Collection {
	var penultimate: Element? {
		guard let index = index(endIndex, offsetBy: -2, limitedBy: startIndex) else {
			return nil
		}
		return self[index]
	}
	
	var antepenultimate: Element? {
		guard let index = index(endIndex, offsetBy: -3, limitedBy: startIndex) else {
			return nil
		}
		return self[index]
	}
}
