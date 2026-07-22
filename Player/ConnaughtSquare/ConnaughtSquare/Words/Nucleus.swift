//
//  Nucleus.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 29/12/2023.
//

/// A nucleus is the central segment of a syllable. It consists of a vowel or a syllabic consonant.
struct Nucleus: SyllableSegment {
	let phoneme: Phoneme
	
	var phonemesCount: Int {
		1
	}
	
	var description: String {
		"N[\(phoneme)]"
	}
}

