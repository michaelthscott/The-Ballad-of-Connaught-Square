//
//  Coda.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 29/12/2023.
//

import Accessibility

/// A coda is the trailing segment of a syllable. It consists of one or more consonants.
struct Coda: SyllableSegment {
	let phonemes: [Phoneme]

	var phonemesCount: Int {
		phonemes.count
	}
	
	var description: String {
		"C\(phonemes)"
	}
}
