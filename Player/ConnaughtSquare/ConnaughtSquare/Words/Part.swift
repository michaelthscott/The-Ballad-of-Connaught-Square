//
//  LinePart.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation
import AVFoundation

/// A part of a line, recited by whichever voice's turn it is.
@Observable final class Part {
    var string: String
    var pronunciations: [CorrectPronunciation]
    var isRecited: Bool
    
    var quotedString: String {
        return "\"\(string)\""
    }
    
    /// The NSAttributedString has AVSpeechSynthesisIPANotationAttribute attributes with \U encoded values.
    var nsAttributedString: NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(string: string)
        let key = NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute)
        for pronunciation in pronunciations {
            let range = NSRange(location: pronunciation.location, length: pronunciation.length)
            mutableAttributedString.addAttribute(key, value: pronunciation.ipa, range: range)
        }

        return NSAttributedString(attributedString: mutableAttributedString)
    }

    init(string: String, pronunciations: [CorrectPronunciation] = [], isRecited: Bool = false) {
        self.string = string
        self.pronunciations = pronunciations
        self.isRecited = isRecited
    }
	
	var duration: Duration {
		string.speakingTime
	}
}

// MARK: Equatable
extension Part: Equatable {
    /// The line parts are equal when their strings are equal.
    /// Note that this assumes the pronunciations are the same.
    /// - Parameters:
    ///   - lhs: The left hand side line part.
    ///   - rhs: The right hand side line part.
    /// - Returns: The result of the comparison.
    static func == (lhs: Part, rhs: Part) -> Bool {
        lhs.string == rhs.string
    }
}

// MARK: - Comparable
extension Part: Comparable {
    /// Line parts are ordered by string comparison.
    /// - Parameters:
    ///   - lhs: The left hand side line part.
    ///   - rhs: The right hand side line part.
    /// - Returns: The result of the comparison.
    static func < (lhs: Part, rhs: Part) -> Bool {
        lhs.string < rhs.string
    }
}

// MARK: - Codable
extension Part: Codable {
    enum CodingKeys: String, CodingKey {
        case string, pronunciations
    }
    
    /// Encodes the line part. The IPA notation is encoded as an array of `CorrectPronunciation`s.
    /// - Parameter encoder: The encoder.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(string, forKey: .string)
        if pronunciations.count > 0 {
            try container.encode(pronunciations, forKey: .pronunciations)
        }
    }
    
    /// Decodes the line part.
    /// - Parameter decoder: The decoder.
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let string = try container.decode(String.self, forKey: .string)
        if container.contains(.pronunciations) {
            let pronunciations = try container.decode(Array<CorrectPronunciation>.self, forKey: .pronunciations)
            self.init(string: string, pronunciations: pronunciations)
        } else {
            self.init(string: string)
        }
    }
}
