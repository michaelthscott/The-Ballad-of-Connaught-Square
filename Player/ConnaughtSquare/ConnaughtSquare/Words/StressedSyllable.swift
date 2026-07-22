//
//  StressedSyllable.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 28/12/2023.
//

import Accessibility

/// There are three types of stressed syllable: final, penultimate and antepenultimate. A rhyme is formed between two words when stressed syllables match.
enum StressedSyllable {
	case final(Syllable)
	case penultimate(Syllable)
	case antepenultimate(Syllable)
}

// MARK: - CustomStringConvertible
extension StressedSyllable: CustomStringConvertible {
	var description: String {
		switch self {
		case .final(let syllable):
			return syllable.description
		case .penultimate(let syllable):
			return syllable.description
		case .antepenultimate(let syllable):
			return syllable.description
		}
	}
}

// MARK: - Equatable
extension StressedSyllable: Equatable {
	static func == (lhs: StressedSyllable, rhs: StressedSyllable) -> Bool {
		lhs.description == rhs.description
	}
}

// MARK: - Hashable
extension StressedSyllable: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.description)
	}
}
