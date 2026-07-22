//
//  SegmentedSyllable.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 29/12/2023.
//

/// A syllable is grouping of phonemes.
struct Syllable {
	var onset: Onset? = nil
	var nucleus: Nucleus
	var coda: Coda? = nil
	
	// FIXME: What about the words like mmm?
	var rhyme: Rhyme? {
		var phonemes: [Phoneme] = []
		phonemes.append(nucleus.phoneme)
		if let coda {
			phonemes.append(contentsOf: coda.phonemes)
		}
		return Rhyme(phonemes: phonemes)
	}

	var ipa: String {
		var ipa = ""
		if let onset {
			for phoneme in onset.phonemes {
				ipa.append(phoneme.ipa)
			}
		}
		ipa.append(nucleus.phoneme.ipa)
		if let coda {
			for phoneme in coda.phonemes {
				ipa.append(phoneme.ipa)
			}
		}
		return ipa
	}
	
	// TODO: This needs to be tested.
	var isStressed: Bool {
		if nucleus.phoneme.stress == .primaryStress {
			return true
		}
		guard let coda else {
			return false
		}
		for phoneme in coda.phonemes {
			if phoneme.stress == .primaryStress {
				return true
			}
		}
		return false
	}
}

// MARK: - CustomStringConvertible
extension Syllable: CustomStringConvertible {
	var description: String {
		var string = ""
		if let onset {
			for phoneme in onset.phonemes {
				string.append(phoneme.description)
			}
			if onset.phonemesCount > 0 {
				string.append("-")
			}
		}
		string.append(nucleus.phoneme.description)
		if let coda {
			if coda.phonemesCount > 0 {
				string.append("-")
			}
			for phoneme in coda.phonemes {
				string.append(phoneme.description)
			}
		}
		return string
	}
}

// MARK: - Equatable
extension Syllable: Equatable {
	static func == (lhs: Syllable, rhs: Syllable) -> Bool {
		lhs.description == rhs.description
	}
}

