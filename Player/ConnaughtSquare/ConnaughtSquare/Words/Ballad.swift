//
//  Ballad.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation

/*
 ABAB or ABCB
 Quatrains
 Repetition of lines.
 Iambic tetrameter or iambic triameter.
 Foot is two syllables, one stressed the other unstressed.
 Iamb is unstressed then stressed.
 ˘ ¯
 First and third lines have eight syllables.
 Second and fourth have six syllables.
 */

/// A collection of lines arranged in ballad form and ordered by linguistic tags and rhymes.
@Observable final class Ballad {
    /// The base collection of lines, initially in archived order. They can be reordered by linguistic tag and/or rhyme.
    var lines: [Line]
    /// The linguistic tags, initially ordered by frequency of use. They can be reordered by the user.
	var tags: LinguisticTagOrder
    
    /// Create a ballad with the property list data.
    convenience init() {
        do {
            let lines: [Line] = try decodeAsset("Lines", from: Bundle.main)
            let tags: LinguisticTagOrder = try decodeAsset("Tags", from: Bundle.main)
            self.init(lines: lines, tags: tags)
        } catch {
            fatalError("Failed to decode the ballad: \(error)")
        }
    }
    
    /// Create a ballad with the specified lines and an ordered linguistic tags.
    /// - Parameters:
    ///   - lines: The lines.
    ///   - tags: The ordered linguistic tags.
	init(lines: [Line] = [], tags: LinguisticTagOrder = LinguisticTagOrder(tags: [])) {
        self.lines = lines
        self.tags = tags
		sortLines()
    }
	
	var title: String {
		"The Ballad of Connaught Square"
	}
	
	/// All the parts of the ballad.
	var parts: [Part] {
		var array: [Part] = []
		for canto in cantos {
			for stanza in canto.stanzas {
				for line in stanza.lines {
					for part in line.parts {
						array.append(part)
					}
				}
			}
		}
		return array
	}
	
    /// A ballad is divided into cantos.  Each canto contains all the stanzas that start with a particular linguistic tag. The parts are ordered according to the ordering of the linguistic tags.
    /// Note that this is dependent on the ordering of the lingustic tags, when they change the ordering of the parts will change.
    /// Stanzas starting with a tag that isn't in the ordering follow in cantos of their own, in the order they first appear.
	var cantos: [Canto] {
		let numberOfLines = 4
        let stanzas = stride(from: 0, to: lines.count, by: numberOfLines).map { startIndex in
			let endIndex = min(startIndex + numberOfLines, lines.count)
			let slice = lines[startIndex..<endIndex]
			return Stanza(lines: slice)
		}
		// Group the stanzas by the tag their first line starts with. A stanza with no tags counts as other words.
		var stanzasByTag: [LinguisticTag: [Stanza]] = [:]
		var tagsInOrderOfAppearance: [LinguisticTag] = []
		for stanza in stanzas {
			let tag = stanza.lines.first?.tags.first ?? .otherWord
			if stanzasByTag[tag] == nil {
				tagsInOrderOfAppearance.append(tag)
			}
			stanzasByTag[tag, default: []].append(stanza)
		}
		// Tags missing from the ordering come after the others, so that no stanza is left out.
		let orderedTags = tags.map { $0.rawValue }
		let cantoTags = orderedTags + tagsInOrderOfAppearance.filter { !orderedTags.contains($0) }
		var newCantos: [Canto] = []
		for tag in cantoTags {
			guard let stanzasStartingWithTag = stanzasByTag[tag] else { continue }
			newCantos.append(Canto(tag: tag, stanzas: stanzasStartingWithTag, number: newCantos.count + 1))
		}
		return newCantos
    }
	
	/// Whether the ballad has been recited.
	/// Note that this means that at least one canto has been recited.
	var isRecited: Bool {
		get {
			for canto in cantos {
				if canto.isRecited {
					return true
				}
			}
			return false
		}
		set {
			for canto in cantos {
				canto.isRecited = newValue
			}
		}
	}
	/// The cantos which have been recited.
	var recitedCantos: [Canto] {
		cantos.filter { $0.isRecited }
	}
	
    /// The lines are sorted first by comparing their tags and then by selecting available rhymes.
    func sortLines() {
        lines = linesSortedByTags(tags)
        lines = linesSortedByRhyme()
    }
	
	/// Sorts the lines using the specified tag order.
	/// - Parameter linguisticTagOrder: The tag order.
	/// - Returns: The sorted lines.
	func linesSortedByTags(_ linguisticTagOrder: LinguisticTagOrder) -> [Line] {
		lines.sorted(by: { lhs, rhs in
			linguisticTagOrder.areOrdered(lhs.tags, rhs.tags)
		})
	}
	
	/// Sorts the lines so that they rhyme as much as possible.
	/// - Returns: The sorted lines.
	func linesSortedByRhyme() -> [Line] {
		var rhymeIndices: [RhymeIndex] = []
		for index in stride(from: lines.startIndex, to: lines.endIndex, by: 1) {
			rhymeIndices.append(RhymeIndex(rhyme: lines[index].rhyme, index: index))
		}
		var sorted: [Line] = []
		var firstRhyme: Rhyme? = nil
		var secondRhyme: Rhyme? = nil
		// TODO: This could probably be improved.
		while true {
			// First line.
			if let nextIndex = rhymeIndices.firstUnusedIndex() {
				sorted.append(lines[nextIndex])
				rhymeIndices[nextIndex].isUnused = false
				firstRhyme = rhymeIndices[nextIndex].rhyme
			}
			// Second line
			if let nextIndex = rhymeIndices.firstUnusedIndex(avoiding: firstRhyme) {
				sorted.append(lines[nextIndex])
				rhymeIndices[nextIndex].isUnused = false
				secondRhyme = rhymeIndices[nextIndex].rhyme
			}
			if rhymeIndices.firstUnusedIndex() == nil {
				break
			}
			// Third line
			if let nextIndex = rhymeIndices.firstUnusedIndex(prefering: firstRhyme) {
				sorted.append(lines[nextIndex])
				rhymeIndices[nextIndex].isUnused = false
			}
			if rhymeIndices.firstUnusedIndex() == nil {
				break
			}
			// Fourth line
			if let nextIndex = rhymeIndices.firstUnusedIndex(prefering: secondRhyme) {
				sorted.append(lines[nextIndex])
				rhymeIndices[nextIndex].isUnused = false
			}
			if rhymeIndices.firstUnusedIndex() == nil {
				break
			}
		}
		return sorted
	}
}
