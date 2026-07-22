//
//  Line.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation
import NaturalLanguage
import Accessibility

// TODO: We initialise this with duplicate information stored in the Property List.
// The string is equal to the joined parts.
// The tags are equal to those parsed from the string.
// The WeightedSet is used to store and provide the tag counts.

/// An individual line containing one or more parts.
@Observable final class Line {
	var parts: [Part]
	let string: String
	let tags: [LinguisticTag]
	private let tagCounts: WeightedSet<WeightedLinguisticTag>

	convenience init(parts: [Part]) {
		let string = parts.map { $0.string }.joined(separator: " ")
		self.init(parts: parts, string: string, tags: LinguisticTagger().linguisticTagsArray(string: string))
	}
	
    /// Creates a line with one or more parts.
    /// Note that the string and tags are assumed to be correct.
    /// - Parameters:
    ///   - parts: The parts of the line.
    ///   - string: The parts joined into a single string.
    ///   - tags: The linguistic tags in the string.
    init(parts: [Part], string: String, tags: [LinguisticTag] = []) {
        self.parts = parts
        self.string = string
        self.tags = tags
		tagCounts = WeightedSet<WeightedLinguisticTag>(tags.map { WeightedLinguisticTag(rawValue: $0, weight: 1)})
    }
	
	var duration: Duration {
		string.speakingTime
	}

	var numberOfParts: Int {
		parts.count
	}
	
	/// Whether the line has been recited.
	/// Note that this means that at least one part has been recited.
    var isRecited: Bool {
		get {
			for part in parts {
				if part.isRecited {
					return true
				}
			}
			return false
		}
		set {
			for part in parts {
				part.isRecited = newValue
			}
		}
    }
	
	/// The recited parts of the line.
	var recitedParts: [Part] {
		parts.filter { $0.isRecited }
	}

	/// Checks whether the first word in the line matches the linguistic tag.
    /// - Parameter tag: A linguistic tag.
    /// - Returns: Whether the line begins with the linguistic tag.
    func startsWith(tag: LinguisticTag) -> Bool {
        guard let first = tags.first else {
            return false
        }
		return first == tag
    }
    
	// TODO: Tags don't change therefore we don't need to repeatedly calculate this.
	func countFor(tag: WeightedLinguisticTag) -> Int {
		tagCounts[tagCounts.position(of: tag)].weight
	}
	
    /// Checks whether the lines rhyme.
    /// - Parameter line: The other line.
    /// - Returns: Whether the lines rhyme.
    func rhymesWith(line: Line) -> Bool {
        guard let lastWord = lastWord, let otherLastWord = line.lastWord else {
            return false
        }
        return lastWord.rhyme == otherLastWord.rhyme
    }
    
    /// Checks whether the line matches the rhyme.
    /// - Parameter rhyme: The rhyme.
    /// - Returns: Whether the line matches the rhyme.
    func endsWith(rhyme: Rhyme) -> Bool {
        guard let lastWord = lastWord else {
            return false
        }
        return lastWord.rhyme == rhyme
    }
    
	// TODO: These two probably doesn't need to be optional.
	
    /// The last word in the line if there is one.
    var lastWord: Word? {
        guard let last = string.components(separatedBy: .whitespaces).last else {
            return nil
        }
        return Lexicon.shared.word(last.trimmingCharacters(in: .punctuationCharacters))
    }
    
    /// The rhyme the line ends with if it is non-empty.
    var rhyme: Rhyme? {
        guard let word = lastWord, let rhyme = word.rhyme else {
            return nil
        }
        return rhyme
    }
    
    /// A string in which shows the individual parts by surrounding them in quotes.
    var quotedString: String {
        parts.map { $0.quotedString }.joined(separator: " ")
    }
}

// MARK: - Codable
extension Line: Codable {
    enum CodingKeys: String, CodingKey {
        case parts, string, tags
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parts, forKey: .parts)
        try container.encode(string, forKey: .string)
        try container.encode(tags.map { $0.name }, forKey: .tags)
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let parts = try container.decode([Part].self, forKey: .parts)
        let string = try container.decode(String.self, forKey: .string)
        let tags = try container.decode([String].self, forKey: .tags)
		self.init(parts: parts, string: string, tags: tags.map { LinguisticTag(rawValue: NLTag($0)) })
    }
}

// MARK: - Equatable
extension Line: Equatable {
    static func == (lhs: Line, rhs: Line) -> Bool {
        lhs.string == rhs.string
    }
}

// MARK: - Comprable
extension Line: Comparable {
    static func < (lhs: Line, rhs: Line) -> Bool {
        return lhs.string < rhs.string
    }
}

// MARK: Identifiable
extension Line: Identifiable {
    
}
