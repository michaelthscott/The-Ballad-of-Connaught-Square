//
//  LinePart.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation
import AVFoundation
import Accessibility

// TODO: We don't use speaker. We assume that parts are spoken by different speakers.

/// Each part of a line is associated with a speaker.
@Observable final class Part {
    private let speaker: Int
    var string: String
    var pronunciations: [CorrectPronunciation]
    var isRecited: Bool
    
    var quotedString: String {
        return "\"\(string)\""
    }
    
    // TODO: These produce different results.
    
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
    
    /// AttributedString has AXIPANotation with unencoded values.
    var attributedString: AttributedString {
        var attrString = AttributedString(string)
        for pronunciation in pronunciations {
            let startIndex = string.index(string.startIndex, offsetBy: pronunciation.location)
            let endIndex = string.index(startIndex, offsetBy: pronunciation.length)
            let substring = string[startIndex..<endIndex]
            guard let range = attrString.range(of: substring) else { return AttributedString() }
            attrString[range].accessibilitySpeechPhoneticNotation = pronunciation.ipa
        }
        return attrString
    }
    
    init(speaker: Int, string: String, pronunciations: [CorrectPronunciation] = [], isRecited: Bool = false) {
        self.speaker = speaker
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
    /// Note that this ignores the speaker, and assumes the pronunciations are the same,
    /// - Parameters:
    ///   - lhs: The left hand side line part.
    ///   - rhs: The right hand side line part.
    /// - Returns: The result of the comparison.
    static func == (lhs: Part, rhs: Part) -> Bool {
        lhs.string == rhs.string && lhs.speaker == rhs.speaker
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
        case speaker, string, pronunciations
    }
    
    /// Encodes the line part. The IPA notation is encoded using NSAttributedString as an array of `CorrectPronunciation`s.
    /// - Parameter encoder: The encoder.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(speaker, forKey: .speaker)
        try container.encode(string, forKey: .string)
        // TODO: Get IPA attributes from AttributedString.
        let key = NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute)
        let copy = NSAttributedString(attributedString)
        var pronunciations: [CorrectPronunciation] = []
        copy.enumerateAttribute(key, in: NSRange(0..<copy.length)) { value, range, stop in
            guard let value = value else {
                return
            }
            pronunciations.append(CorrectPronunciation(ipa: value as! String, location: range.location, length: range.length))
        }
        if pronunciations.count > 0 {
            try container.encode(pronunciations, forKey: .pronunciations)
        }
    }
    
    /// Decodes the line part.
    /// - Parameter decoder: The decoder.
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let speaker = try container.decode(Int.self, forKey: .speaker)
        let string = try container.decode(String.self, forKey: .string)
        if container.contains(.pronunciations) {
            let pronunciations = try container.decode(Array<CorrectPronunciation>.self, forKey: .pronunciations)
            self.init(speaker: speaker, string: string, pronunciations: pronunciations)
        } else {
            self.init(speaker: speaker, string: string)
        }
    }
}
