//
//  WeightedLinguisticTag.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 11/12/2023.
//

import NaturalLanguage
import Accessibility

enum WeightedLinguisticTag {
    case noun(weight: Int = 0)
    case verb(weight: Int = 0)
    case adjective(weight: Int = 0)
    case adverb(weight: Int = 0)
    case pronoun(weight: Int = 0)
    case determiner(weight: Int = 0)
    case particle(weight: Int = 0)
    case preposition(weight: Int = 0)
    case number(weight: Int = 0)
    case conjunction(weight: Int = 0)
    case interjection(weight: Int = 0)
    case classifier(weight: Int = 0)
    case idiom(weight: Int = 0)
    case otherWord(weight: Int = 0)
    case personalName(weight: Int = 0)
    case organizationName(weight: Int = 0)
    case placeName(weight: Int = 0)
}

extension WeightedLinguisticTag: SafeRawRepresentable {
    typealias RawValue = LinguisticTag
    
    init(rawValue: LinguisticTag) {
        self.init(rawValue: rawValue, weight: 0)
    }

    init(rawValue: LinguisticTag, weight: Int) {
        switch rawValue {
        case .noun:
            self = .noun(weight: weight)
        case .verb:
            self = .verb(weight: weight)
        case .adjective:
            self = .adjective(weight: weight)
        case .adverb:
            self = .adverb(weight: weight)
        case .pronoun:
            self = .pronoun(weight: weight)
        case .determiner:
            self = .determiner(weight: weight)
        case .particle:
            self = .particle(weight: weight)
        case .preposition:
            self = .preposition(weight: weight)
        case .number:
            self = .number(weight: weight)
        case .conjunction:
            self = .conjunction(weight: weight)
        case .interjection:
            self = .interjection(weight: weight)
        case .classifier:
            self = .classifier(weight: weight)
        case .idiom:
            self = .idiom(weight: weight)
        case .otherWord:
            self = .otherWord(weight: weight)
        case .personalName:
            self = .personalName(weight: weight)
        case .organizationName:
            self = .organizationName(weight: weight)
        case .placeName:
            self = .placeName(weight: weight)
        }
    }
    
    // TODO: Remove () from LinguisticTag enum values when weight has been removed from LinguisticTag.
    
    var rawValue: LinguisticTag {
        switch self {
        case .noun:
            return LinguisticTag.noun
        case .verb:
            return LinguisticTag.verb
        case .adjective:
            return LinguisticTag.adjective
        case .adverb:
            return LinguisticTag.adverb
        case .pronoun:
            return LinguisticTag.pronoun
        case .determiner:
            return LinguisticTag.determiner
        case .particle:
            return LinguisticTag.particle
        case .preposition:
            return LinguisticTag.preposition
        case .number:
            return LinguisticTag.number
        case .conjunction:
            return LinguisticTag.conjunction
        case .interjection:
            return LinguisticTag.interjection
        case .classifier:
            return LinguisticTag.classifier
        case .idiom:
            return LinguisticTag.idiom
        case .otherWord:
            return LinguisticTag.otherWord
        case .personalName:
            return LinguisticTag.personalName
        case .organizationName:
            return LinguisticTag.organizationName
        case .placeName:
            return LinguisticTag.placeName
        }
    }
}

extension WeightedLinguisticTag: Weighted {
    var weight: Int {
        mutating set {
            switch self {
            case .noun:
                self = .noun(weight: newValue)
            case .verb:
                self = .verb(weight: newValue)
            case .adjective:
                self = .adjective(weight: newValue)
            case .adverb:
                self = .adverb(weight: newValue)
            case .pronoun:
                self = .pronoun(weight: newValue)
            case .determiner:
                self = .determiner(weight: newValue)
            case .particle:
                self = .particle(weight: newValue)
            case .preposition:
                self = .preposition(weight: newValue)
            case .number:
                self = .number(weight: newValue)
            case .conjunction:
                self = .conjunction(weight: newValue)
            case .interjection:
                self = .interjection(weight: newValue)
            case .classifier:
                self = .classifier(weight: newValue)
            case .idiom:
                self = .idiom(weight: newValue)
            case .otherWord:
                self = .otherWord(weight: newValue)
            case .personalName:
                self = .personalName(weight: newValue)
            case .organizationName:
                self = .organizationName(weight: newValue)
            case .placeName:
                self = .placeName(weight: newValue)
            }
        }
        get {
            switch self {
            case .noun(let weight):
                return weight
            case .verb(let weight):
                return weight
            case .adjective(let weight):
                return weight
            case .adverb(let weight):
                return weight
            case .pronoun(let weight):
                return weight
            case .determiner(let weight):
                return weight
            case .particle(let weight):
                return weight
            case .preposition(let weight):
                return weight
            case .number(let weight):
                return weight
            case .conjunction(let weight):
                return weight
            case .interjection(let weight):
                return weight
            case .classifier(let weight):
                return weight
            case .idiom(let weight):
                return weight
            case .otherWord(let weight):
                return weight
            case .personalName(let weight):
                return weight
            case .organizationName(let weight):
                return weight
            case .placeName(let weight):
                return weight
            }
        }
    }
    
    var name: String {
        rawValue.name
    }
}

extension WeightedLinguisticTag: CaseIterable {
    static let allCases: [WeightedLinguisticTag] = [.noun(), .verb(), .adjective(), .adverb(), .pronoun(), .determiner(), .particle(), .preposition(), .number(), .conjunction(), .interjection(), .classifier(), .idiom(), .otherWord(), .personalName(), .organizationName(), .placeName()]
}

/*
 a == a is always true (Reflexivity)
 a == b implies b == a (Symmetry)
 a == b and b == c implies a == c (Transitivity)
 */

extension WeightedLinguisticTag: Equatable {
    /// Two tags are equal when their raw values are equal. Weights are ignored.
    /// - Parameters:
    ///   - lhs: The left-hand  tag.
    ///   - rhs: The right-hand  tag.
    /// - Returns: Whether the tags are equal.
	static func == (lhs: WeightedLinguisticTag, rhs: WeightedLinguisticTag) -> Bool {
		lhs.rawValue == rhs.rawValue
	}
	// Useful for testing.
	static func == (lhs: WeightedLinguisticTag, rhs: LinguisticTag) -> Bool {
		lhs.rawValue == rhs
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

extension WeightedLinguisticTag: Comparable {
    public static func < (lhs: WeightedLinguisticTag, rhs: WeightedLinguisticTag) -> Bool {
        if lhs.weight == rhs.weight {
            return lhs.name < rhs.name
        }
        return lhs.weight > rhs.weight
    }
}

extension WeightedLinguisticTag: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case weight
    }
    
    /// Encodes the tag order.
    /// - Parameter encoder: The encoder.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawValue.rawValue.rawValue, forKey: .name)
        try container.encode(weight, forKey: .weight)
    }
    
    /// Decodes the ballad.
    /// - Parameter decoder: The decoder.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let weight = try container.decode(Int.self, forKey: .weight)
        self.init(rawValue: LinguisticTag(rawValue: NLTag(name)), weight: weight)
    }
}

extension WeightedLinguisticTag: Hashable {
	
}

extension WeightedLinguisticTag: CustomStringConvertible {
    var description: String {
        "\(name)(\(weight))"
    }
}

extension WeightedLinguisticTag: Identifiable {
	var id: String {
		description
	}
}
