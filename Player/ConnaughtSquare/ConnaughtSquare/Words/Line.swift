//
//  Line.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation
import NaturalLanguage
import Accessibility

// The tags are stored with the lines rather than parsed from the string, as the app never tags at runtime:
// some run destinations lack the tagger's assets, and its results can change between OS versions.
// The WeightedSet is used to store and provide the tag counts.

/// An individual line containing one or more parts.
@Observable final class Line {
	var parts: [Part]
	/// The parts joined into a single string.
	let string: String
	let tags: [LinguisticTag]
	private let tagCounts: WeightedSet<WeightedLinguisticTag>

	/// Creates a line with one or more parts, tagging the joined string.
	/// - Parameter parts: The parts of the line.
	/// - Throws: ``LinguisticTaggerError/tagSchemeUnavailable(_:_:)`` when the tag scheme isn't available on this device.
	convenience init(parts: [Part]) throws {
		let string = Line.string(joining: parts)
		self.init(parts: parts, tags: try LinguisticTagger().linguisticTagsArray(string: string))
	}

    /// Creates a line with one or more parts.
    /// Note that the tags are assumed to be correct.
    /// - Parameters:
    ///   - parts: The parts of the line.
    ///   - tags: The linguistic tags in the joined parts.
    init(parts: [Part], tags: [LinguisticTag]) {
        self.parts = parts
        self.string = Line.string(joining: parts)
        self.tags = tags
		tagCounts = WeightedSet<WeightedLinguisticTag>(tags.map { WeightedLinguisticTag(rawValue: $0, weight: 1)})
    }

	/// The parts' strings joined with spaces.
	private static func string(joining parts: [Part]) -> String {
		parts.map { $0.string }.joined(separator: " ")
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
    
	/// The number of times the tag appears in the line.
	func countFor(tag: WeightedLinguisticTag) -> Int {
		tagCounts.weight(of: tag)
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
        case parts, tags
    }

    /// Encodes the line's parts and tags. The string isn't encoded, as it's the joined parts.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parts, forKey: .parts)
        try container.encode(tags.map { $0.name }, forKey: .tags)
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let parts = try container.decode([Part].self, forKey: .parts)
        let tags = try container.decode([String].self, forKey: .tags)
		self.init(parts: parts, tags: tags.map { LinguisticTag(rawValue: NLTag($0)) })
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
