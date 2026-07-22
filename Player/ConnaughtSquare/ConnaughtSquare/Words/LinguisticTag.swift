//
//  LinguisticTag.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 07/11/2023.
//

import Foundation
import NaturalLanguage

/// ``LinguisticTag`` is a wrapper around `NLTag` so that there are a specific set of possible tags produced by ``LinguisticTagger``.  By default the weight of a tag is zero.
enum LinguisticTag {
    case noun
    case verb
    case adjective
    case adverb
    case pronoun
    case determiner
    case particle
    case preposition
    case number
    case conjunction
    case interjection
    case classifier
    case idiom
    case otherWord
    case personalName
    case organizationName
    case placeName
}

/*
 a == a is always true (Reflexivity)
 a == b implies b == a (Symmetry)
 a == b and b == c implies a == c (Transitivity)
 */

extension LinguisticTag: Equatable {
    /// Two tags are equal when their raw values are equal. Weights are ignored.
    /// - Parameters:
    ///   - lhs: The left-hand  tag.
    ///   - rhs: The right-hand  tag.
    /// - Returns: Whether the tags are equal.
    static func == (lhs: LinguisticTag, rhs: LinguisticTag) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

/*
 a == a is always true (Reflexivity)
 a == b implies b == a (Symmetry)
 a == b and b == c implies a == c (Transitivity)
 a < a is always false (Irreflexivity)
 a < b implies !(b < a) (Asymmetry)
 a < b and b < c implies a < c (Transitivity)
 */

extension LinguisticTag: Comparable {
    /// Tags are ordered by weight, and raw value when weights are equal.
    /// - Parameters:
    ///   - lhs: The left-hand  tag.
    ///   - rhs: The right-hand  tag.
    /// - Returns: Whether the left-hand tag is ordered before the right-hand tag.
    static func < (lhs: LinguisticTag, rhs: LinguisticTag) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// For the above comparison. The raw value of an NLTag is the name of the tag.
extension NLTag: @retroactive Comparable {
    /// Compares the raw values of two `NLTag`s .
    /// - Parameters:
    ///   - lhs: Left-hand tag.
    ///   - rhs: Right-hand tag.
    /// - Returns: Whether the left-hand tag is ordered before the right-hand tag.
    public static func < (lhs: NLTag, rhs: NLTag) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension LinguisticTag: Hashable {
	
}

extension LinguisticTag: RawRepresentable {
    init(rawValue: NLTag) {
        switch rawValue {
        case .noun:
            self = .noun
        case .verb:
            self = .verb
        case .adjective:
            self = .adjective
        case .adverb:
            self = .adverb
        case .pronoun:
            self = .pronoun
        case .determiner:
            self = .determiner
        case .particle:
            self = .particle
        case .preposition:
            self = .preposition
        case .number:
            self = .number
        case .conjunction:
            self = .conjunction
        case .interjection:
            self = .interjection
        case .classifier:
            self = .classifier
        case .idiom:
            self = .idiom
        case .otherWord:
            self = .otherWord
        case .personalName:
            self = .personalName
        case .organizationName:
            self = .organizationName
        case .placeName:
            self = .placeName
        default:
            self = .otherWord // Because NLTag is not an enum we need this as a kind of undefined default.
        }
    }

    var rawValue: NLTag {
        switch self {
        case .noun:
            return .noun
        case .verb:
            return .verb
        case .adjective:
            return .adjective
        case .adverb:
            return .adverb
        case .pronoun:
            return .pronoun
        case .determiner:
            return .determiner
        case .particle:
            return .particle
        case .preposition:
            return .preposition
        case .number:
            return .number
        case .conjunction:
            return .conjunction
        case .interjection:
            return .interjection
        case .classifier:
            return .classifier
        case .idiom:
            return .idiom
        case .otherWord:
            return .otherWord
        case .personalName:
            return .personalName
        case .organizationName:
            return .organizationName
        case .placeName:
            return .placeName
        }
    }

    var name: String {
        rawValue.rawValue
    }
}

extension LinguisticTag: CaseIterable {
    /// The initial default cases with zero weight.
    nonisolated(unsafe) static var allCases: [LinguisticTag] = [.noun, .verb, .adjective, .adverb, .pronoun, .determiner, .particle, .preposition, .number, .conjunction, .interjection, .classifier, .idiom, .otherWord, .personalName, .organizationName, .placeName]
}

extension LinguisticTag: CustomStringConvertible {
    var description: String {
        "\(name)"
    }
}

extension LinguisticTag: Codable {
    enum CodingKeys: String, CodingKey {
        case name
    }
    
    /// Encodes the tag order.
    /// - Parameter encoder: The encoder.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
    
    /// Decodes the ballad.
    /// - Parameter decoder: The decoder.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        self.init(rawValue: NLTag(name))
    }
}
