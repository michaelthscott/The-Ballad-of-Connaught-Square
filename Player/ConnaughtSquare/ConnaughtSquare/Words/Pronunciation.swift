//
//  Pronunciation.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

/// A pronunciation consists of a number of phonemes.
struct Pronunciation {
    let phonemes: [Phoneme]
	
	/// The phonemes grouped into syllables.
	var syllables: [Syllable] {
		var syllables: [Syllable] = []
		let segments = syllableSegments
		var onset: Onset! = nil
		var nucleus: Nucleus! = nil
		var coda: Coda! = nil
		for index in stride(from: segments.startIndex, to: segments.endIndex, by: 1) {
			switch segments[index] {
			case is Onset:
				onset = segments[index] as? Onset
			case is Nucleus:
				nucleus = segments[index] as? Nucleus
			case is Coda:
				coda = segments[index] as? Coda
			default:
				()
			}
			if nucleus != nil {
				let nextIndex = segments.index(after: index)
				if nextIndex == segments.endIndex {
					syllables.append(Syllable(onset: onset, nucleus: nucleus, coda: coda))
					break
				} else if segments[nextIndex] is Onset {
					syllables.append(Syllable(onset: onset, nucleus: nucleus, coda: coda))
					onset = nil
					nucleus = nil
					coda = nil
				}
			}
		}
		return syllables

	}
	
	/// The phonemes grouped into syllable segments, i.e. onset, nucleus and coda.
	var syllableSegments: [SyllableSegment] {
		var segments: [SyllableSegment] = []
		var index = phonemes.startIndex
		if let segment = phonemes[index..<phonemes.endIndex].onset() {
			segments.append(segment)
		}
		while index < phonemes.count {
			let array = phonemes[index..<phonemes.endIndex].nuclei()
			if array.count > 0 {
				segments.append(contentsOf: array)
			}
			index = segments.reduce(0, { partialResult, segment in
				partialResult + segment.phonemesCount
			})
			guard index < phonemes.count else {
				break
			}
			if phonemes[index..<phonemes.endIndex].containsNoVowel() {
				if let segment = phonemes[index..<phonemes.endIndex].coda() {
					segments.append(segment)
				}
				break
			} else {
				let array = phonemes[index..<phonemes.endIndex].codaAndLegalOnset()
				if array.count > 0 {
					segments.append(contentsOf: array)
				}
			}
		}
		return  segments
	}
}

// MARK: - Equatable
extension Pronunciation: Equatable {}

// MARK: - Codable
extension Pronunciation: Codable {}

// MARK: - CustomStringConvertible
extension Pronunciation: CustomStringConvertible {
    var description: String {
        "\(phonemes)"
    }
}

// MARK: - ArraySlice<Phoneme> Comparable
extension ArraySlice<Phoneme> {
	func onset() -> Onset? {
		let consonants = prefix(while: { $0.isConsonant })
		guard consonants.count > 0 else { return nil }
		return Onset(phonemes: Array(consonants))
	}
	
	func nuclei() -> [Nucleus] {
		let vowels = prefix(while: { $0.isVowel })
		guard vowels.count > 0 else { return [] }
		var nuclei: [Nucleus] = []
		for vowel in vowels {
			nuclei.append(Nucleus(phoneme: vowel))
		}
		return nuclei
	}
	
	func coda() -> Coda? {
		let consonants = prefix(while: { $0.isConsonant })
		guard consonants.count > 0 else { return nil }
		return Coda(phonemes: Array(consonants))
	}

	func codaAndLegalOnset() -> [SyllableSegment] {
		var consonants = prefix(while: { $0.isConsonant })
		var onsetPhonemes: [Phoneme] = Array(consonants)
		var codaPhonemes: [Phoneme] = []
		while consonants.count > 0 {
			if consonants.isLegalOnset() {
				break
			} else {
				codaPhonemes.append(consonants.removeFirst())
				onsetPhonemes.removeFirst()
			}
		}
		var segments: [SyllableSegment] = []
		if codaPhonemes.count > 0 {
			segments.append(Coda(phonemes: codaPhonemes))
		}
		if onsetPhonemes.count > 0 {
			segments.append(Onset(phonemes: onsetPhonemes))
		}
		return segments
	}

    func containsNoVowel() -> Bool {
        allSatisfy { $0.isConsonant }
    }
    
    func isLegalOnset() -> Bool {
        guard count <= 3 else {
            return false
        }
        // These have been generated from cmudict.
        let legalOnsets: Set<[Phoneme]> = [
            [Phoneme(sound: .B)],
            [Phoneme(sound: .B), Phoneme(sound: .L)],
            [Phoneme(sound: .B), Phoneme(sound: .L), Phoneme(sound: .W)],
            [Phoneme(sound: .B), Phoneme(sound: .R)],
            [Phoneme(sound: .B), Phoneme(sound: .R), Phoneme(sound: .W)],
            [Phoneme(sound: .B), Phoneme(sound: .W)],
            [Phoneme(sound: .B), Phoneme(sound: .Y)],
            [Phoneme(sound: .CH)],
            [Phoneme(sound: .CH), Phoneme(sound: .L)],
            [Phoneme(sound: .CH), Phoneme(sound: .R)],
            [Phoneme(sound: .CH), Phoneme(sound: .W)],
            [Phoneme(sound: .CH), Phoneme(sound: .Y)],
            [Phoneme(sound: .D)],
            [Phoneme(sound: .D), Phoneme(sound: .HH)],
            [Phoneme(sound: .D), Phoneme(sound: .M)],
            [Phoneme(sound: .D), Phoneme(sound: .N)],
            [Phoneme(sound: .D), Phoneme(sound: .R)],
            [Phoneme(sound: .D), Phoneme(sound: .R), Phoneme(sound: .W)],
            [Phoneme(sound: .D), Phoneme(sound: .V)],
            [Phoneme(sound: .D), Phoneme(sound: .W)],
            [Phoneme(sound: .D), Phoneme(sound: .Y)],
            [Phoneme(sound: .D), Phoneme(sound: .Z)],
            [Phoneme(sound: .DH)],
            [Phoneme(sound: .DH), Phoneme(sound: .Y)],
            [Phoneme(sound: .F)],
            [Phoneme(sound: .F), Phoneme(sound: .L)],
            [Phoneme(sound: .F), Phoneme(sound: .N)],
            [Phoneme(sound: .F), Phoneme(sound: .R)],
            [Phoneme(sound: .F), Phoneme(sound: .S)],
            [Phoneme(sound: .F), Phoneme(sound: .TH)],
            [Phoneme(sound: .F), Phoneme(sound: .W)],
            [Phoneme(sound: .F), Phoneme(sound: .Y)],
            [Phoneme(sound: .G)],
            [Phoneme(sound: .G), Phoneme(sound: .D)],
            [Phoneme(sound: .G), Phoneme(sound: .L)],
            [Phoneme(sound: .G), Phoneme(sound: .R)],
            [Phoneme(sound: .G), Phoneme(sound: .W)],
            [Phoneme(sound: .G), Phoneme(sound: .Y)],
            [Phoneme(sound: .HH)],
            [Phoneme(sound: .HH), Phoneme(sound: .L)],
            [Phoneme(sound: .HH), Phoneme(sound: .M)],
            [Phoneme(sound: .HH), Phoneme(sound: .N)],
            [Phoneme(sound: .HH), Phoneme(sound: .R)],
            [Phoneme(sound: .HH), Phoneme(sound: .W)],
            [Phoneme(sound: .HH), Phoneme(sound: .Y)],
            [Phoneme(sound: .JH)],
            [Phoneme(sound: .JH), Phoneme(sound: .F)],
            [Phoneme(sound: .JH), Phoneme(sound: .W)],
            [Phoneme(sound: .JH), Phoneme(sound: .Y)],
            [Phoneme(sound: .K)],
            [Phoneme(sound: .K), Phoneme(sound: .L)],
            [Phoneme(sound: .K), Phoneme(sound: .M)],
            [Phoneme(sound: .K), Phoneme(sound: .N)],
            [Phoneme(sound: .K), Phoneme(sound: .R)],
            [Phoneme(sound: .K), Phoneme(sound: .S), Phoneme(sound: .Y)],
            [Phoneme(sound: .K), Phoneme(sound: .V)],
            [Phoneme(sound: .K), Phoneme(sound: .W)],
            [Phoneme(sound: .K), Phoneme(sound: .Y)],
            [Phoneme(sound: .L)],
            [Phoneme(sound: .L), Phoneme(sound: .HH), Phoneme(sound: .Y)],
            [Phoneme(sound: .L), Phoneme(sound: .K), Phoneme(sound: .S)],
            [Phoneme(sound: .L), Phoneme(sound: .W)],
            [Phoneme(sound: .L), Phoneme(sound: .Y)],
            [Phoneme(sound: .M)],
            [Phoneme(sound: .M), Phoneme(sound: .B)],
            [Phoneme(sound: .M), Phoneme(sound: .HH)],
            [Phoneme(sound: .M), Phoneme(sound: .L)],
            [Phoneme(sound: .M), Phoneme(sound: .N)],
            [Phoneme(sound: .M), Phoneme(sound: .R)],
            [Phoneme(sound: .M), Phoneme(sound: .W)],
            [Phoneme(sound: .M), Phoneme(sound: .Y)],
            [Phoneme(sound: .N)],
            [Phoneme(sound: .N), Phoneme(sound: .D)],
            [Phoneme(sound: .N), Phoneme(sound: .D), Phoneme(sound: .Y)],
            [Phoneme(sound: .N), Phoneme(sound: .W)],
            [Phoneme(sound: .N), Phoneme(sound: .Y)],
            [Phoneme(sound: .P)],
            [Phoneme(sound: .P), Phoneme(sound: .L)],
            [Phoneme(sound: .P), Phoneme(sound: .R)],
            [Phoneme(sound: .P), Phoneme(sound: .SH)],
            [Phoneme(sound: .P), Phoneme(sound: .W)],
            [Phoneme(sound: .P), Phoneme(sound: .Y)],
            [Phoneme(sound: .R)],
            [Phoneme(sound: .R), Phoneme(sound: .W)],
            [Phoneme(sound: .R), Phoneme(sound: .Y)],
            [Phoneme(sound: .S)],
            [Phoneme(sound: .S), Phoneme(sound: .B)],
            [Phoneme(sound: .S), Phoneme(sound: .F)],
            [Phoneme(sound: .S), Phoneme(sound: .HH)],
            [Phoneme(sound: .S), Phoneme(sound: .K)],
            [Phoneme(sound: .S), Phoneme(sound: .K), Phoneme(sound: .L)],
            [Phoneme(sound: .S), Phoneme(sound: .K), Phoneme(sound: .R)],
            [Phoneme(sound: .S), Phoneme(sound: .K), Phoneme(sound: .W)],
            [Phoneme(sound: .S), Phoneme(sound: .K), Phoneme(sound: .Y)],
            [Phoneme(sound: .S), Phoneme(sound: .L)],
            [Phoneme(sound: .S), Phoneme(sound: .M)],
            [Phoneme(sound: .S), Phoneme(sound: .M), Phoneme(sound: .R)],
            [Phoneme(sound: .S), Phoneme(sound: .N)],
            [Phoneme(sound: .S), Phoneme(sound: .P)],
            [Phoneme(sound: .S), Phoneme(sound: .P), Phoneme(sound: .L)],
            [Phoneme(sound: .S), Phoneme(sound: .P), Phoneme(sound: .R)],
            [Phoneme(sound: .S), Phoneme(sound: .P), Phoneme(sound: .Y)],
            [Phoneme(sound: .S), Phoneme(sound: .R)],
            [Phoneme(sound: .S), Phoneme(sound: .T)],
            [Phoneme(sound: .S), Phoneme(sound: .T), Phoneme(sound: .R)],
            [Phoneme(sound: .S), Phoneme(sound: .T), Phoneme(sound: .Y)],
            [Phoneme(sound: .S), Phoneme(sound: .V)],
            [Phoneme(sound: .S), Phoneme(sound: .W)],
            [Phoneme(sound: .S), Phoneme(sound: .Y)],
            [Phoneme(sound: .SH)],
            [Phoneme(sound: .SH), Phoneme(sound: .L)],
            [Phoneme(sound: .SH), Phoneme(sound: .M)],
            [Phoneme(sound: .SH), Phoneme(sound: .N)],
            [Phoneme(sound: .SH), Phoneme(sound: .R)],
            [Phoneme(sound: .SH), Phoneme(sound: .T)],
            [Phoneme(sound: .SH), Phoneme(sound: .V)],
            [Phoneme(sound: .SH), Phoneme(sound: .W)],
            [Phoneme(sound: .SH), Phoneme(sound: .Y)],
            [Phoneme(sound: .T)],
            [Phoneme(sound: .T), Phoneme(sound: .L)],
            [Phoneme(sound: .T), Phoneme(sound: .R)],
            [Phoneme(sound: .T), Phoneme(sound: .S)],
            [Phoneme(sound: .T), Phoneme(sound: .S), Phoneme(sound: .Y)],
            [Phoneme(sound: .T), Phoneme(sound: .V)],
            [Phoneme(sound: .T), Phoneme(sound: .W)],
            [Phoneme(sound: .T), Phoneme(sound: .Y)],
            [Phoneme(sound: .TH)],
            [Phoneme(sound: .TH), Phoneme(sound: .R)],
            [Phoneme(sound: .TH), Phoneme(sound: .W)],
            [Phoneme(sound: .TH), Phoneme(sound: .Y)],
            [Phoneme(sound: .V)],
            [Phoneme(sound: .V), Phoneme(sound: .L)],
            [Phoneme(sound: .V), Phoneme(sound: .R)],
            [Phoneme(sound: .V), Phoneme(sound: .W)],
            [Phoneme(sound: .V), Phoneme(sound: .Y)],
            [Phoneme(sound: .W)],
            [Phoneme(sound: .W), Phoneme(sound: .N)],
            [Phoneme(sound: .Y)],
            [Phoneme(sound: .Y), Phoneme(sound: .W)],
            [Phoneme(sound: .Z)],
            [Phoneme(sound: .Z), Phoneme(sound: .B)],
            [Phoneme(sound: .Z), Phoneme(sound: .D), Phoneme(sound: .R)],
            [Phoneme(sound: .Z), Phoneme(sound: .L)],
            [Phoneme(sound: .Z), Phoneme(sound: .M)],
            [Phoneme(sound: .Z), Phoneme(sound: .V)],
            [Phoneme(sound: .Z), Phoneme(sound: .W)],
            [Phoneme(sound: .Z), Phoneme(sound: .Y)],
            [Phoneme(sound: .ZH)],
            [Phoneme(sound: .ZH), Phoneme(sound: .W)]
        ]
        
        return legalOnsets.contains(Array(self))
    }
}
