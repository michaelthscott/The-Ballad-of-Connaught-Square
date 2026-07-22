//
//  Onset.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 29/12/2023.
//

/// An onset is the leading segment of a syllable. It consists of one or more consonants.
struct Onset: SyllableSegment {
	let phonemes: [Phoneme]
	
	var phonemesCount: Int {
		phonemes.count
	}
	
	var description: String {
		"O\(phonemes)"
	}
}
