//
//  RhymeType.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 30/12/2023.
//

import Accessibility

enum RhymeType: String {
	// Perfect rhymes
	case single = "Single"
	case double = "Double"
	case dactylic = "Dactylic"
	// General rhymes
	case syllabic = "Syllabic"
	case imperfect = "Imperfect"
	case weak = "Weak"
	case semi = "Semirhyme"
	case forced = "Forced"
	case assonance = "Assonance"
	case consonance = "Consonance"
	case half = "Half Rhyme"
	case pararhyme = "Pararhyme"
	case alliteration = "Alliteration"
}

extension RhymeType: CaseIterable {
	
}

extension RhymeType: CustomStringConvertible {
	var description: String {
		rawValue
	}
}

extension RhymeType {
	func linesRhyme(_ lines: LinePair) -> Bool {
		switch self {
		case .single:
			return isSingleRhyme(lines)
		case .double:
			return isDoubleRhyme(lines)
		case .dactylic:
			return isDactylicRhyme(lines)
		case .syllabic:
			return isSyllabicRhyme(lines)
		case .imperfect:
			return isImperfectRhyme(lines)
		case .weak:
			return isWeakRhyme(lines)
		case .semi:
			return isSemiRhyme(lines)
		case .forced:
			return isForcedRhyme(lines)
		case .assonance:
			return isAssonanceRhyme(lines)
		case .consonance:
			return isConsonanceRhyme(lines)
		case .half:
			return isHalfRhyme(lines)
		case .pararhyme:
			return isParaRhyme(lines)
		case .alliteration:
			return isAlliterationRhyme(lines)
		}
	}
	
	/// A rhyme in which the stress is on the final syllable.
	func isSingleRhyme(_ pair: LinePair) -> Bool {
		guard let first = pair.first.lastWord?.finalStressedSyllable, let second = pair.second.lastWord?.finalStressedSyllable else {
			return false
		}
		return first == second
	}
	
	/// A rhyme in which the stress is on the penultimate (second from last) syllable.
	func isDoubleRhyme(_ pair: LinePair) -> Bool {
		guard let first = pair.first.lastWord?.penultimateStressedSyllable, let second = pair.second.lastWord?.penultimateStressedSyllable else {
			return false
		}
		return first == second
	}
	
	/// A rhyme in which the stress is on the antepenultimate (third from last) syllable.
	func isDactylicRhyme(_ pair: LinePair) -> Bool {
		guard let first = pair.first.lastWord?.antepenultimateStressedSyllable, let second = pair.second.lastWord?.antepenultimateStressedSyllable else {
			return false
		}
		return first == second
	}
	
	// A rhyme in which the last syllable of each word sounds the same but does not necessarily contain stressed vowels.
	func isSyllabicRhyme(_ pair: LinePair) -> Bool {
		guard let first = pair.first.lastWord?.finalSyllable, let second = pair.second.lastWord?.finalSyllable else {
			return false
		}
		return first == second
	}
	
	// TODO: Are these final syllables or syllables in equivalent positons (from the end?).
	// A rhyme between a stressed and an unstressed syllable
	func isImperfectRhyme(_ pair: LinePair) -> Bool {
		return false
	}
	
	// TODO: Are these final syllables or syllables in equivalent positons (from the end?).
	// A rhyme between two sets of one or more unstressed syllables.
	func isWeakRhyme(_ pair: LinePair) -> Bool {
		return false
	}
	
	// TODO: Is this a single rhyme with and extra (leading?) syllable in one word.
	// A rhyme with an extra syllable on one word.
	func isSemiRhyme(_ pair: LinePair) -> Bool {
		return false
	}
	
	// TODO: What is this?
	// A rhyme with an imperfect match in sound.
	func isForcedRhyme(_ pair: LinePair) -> Bool {
		return false
	}
	
	// TODO: Is the match of at least one correct?
	// Matching vowels.
	func isAssonanceRhyme(_ pair: LinePair) -> Bool {
		guard let first = pair.first.lastWord?.vowels, let second = pair.second.lastWord?.vowels else {
			return false
		}
		let match = first.filter({ second.contains($0) })
		return match.count > 0
	}
	
	// TODO: Is the match of at least one correct?
	// Matching consonants.
	func isConsonanceRhyme(_ pair: LinePair) -> Bool {
		guard let first = pair.first.lastWord?.consonants, let second = pair.second.lastWord?.consonants else {
			return false
		}
		let match = first.filter({ second.contains($0) })
		return match.count > 0
	}
	
	// Matching final consonants.
	func isHalfRhyme(_ pair: LinePair) -> Bool {
		guard let first = pair.first.lastWord?.consonants.last, let second = pair.second.lastWord?.consonants.last else {
			return false
		}
		return first == second
	}
	
	// All consonants match.
	func isParaRhyme(_ pair: LinePair) -> Bool {
		guard let first = pair.first.lastWord?.consonants, let second = pair.second.lastWord?.consonants else {
			return false
		}
		return first == second
	}
	
	// Matching initial consonants.
	func isAlliterationRhyme(_ pair: LinePair) -> Bool {
		guard let first = pair.first.lastWord?.consonants.first, let second = pair.second.lastWord?.consonants.first else {
			return false
		}
		return first == second
	}
}

