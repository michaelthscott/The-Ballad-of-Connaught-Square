//
//  Tagger.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/11/2023.
//

import Foundation
import NaturalLanguage

/// A wrapper around `NSTagger` that limits the tags to name types and lexical tags. White space and punctuation are ignored. Names are joined.
struct LinguisticTagger {
    let tagScheme: NLTagScheme = .nameTypeOrLexicalClass
    let taggerOptions: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
    /// Analyses the string into its constituent tags.
    /// - Parameter string: A string.
    /// - Returns: The linguistic tags for the string.
    func linguisticTagsArray(string: String) -> [LinguisticTag] {
        let tagger = NLTagger(tagSchemes: [tagScheme])
        tagger.string = string
        let range = string.startIndex..<string.endIndex
        tagger.setLanguage(.english, range: range)
        var tags: [LinguisticTag] = []
        tagger.enumerateTags(in: range, unit: .word, scheme: tagScheme, options: taggerOptions) { tag, tokenRange in
            if let tag = tag {
                tags.append(LinguisticTag(rawValue: tag))
            }
            // Whether to continue.
            return true
        }
        return tags
    }

//    /// Analyses the string into its constituent tags.
//    /// - Parameter string: A string.
//    /// - Returns: The linguistic tags for the string.
//    func tagsArray(string: String) -> [NLTag] {
//        let tagger = NLTagger(tagSchemes: [tagScheme])
//        tagger.string = string
//        let range = string.startIndex..<string.endIndex
//        tagger.setLanguage(.english, range: range)
//        var tags: [NLTag] = []
//        tagger.enumerateTags(in: range, unit: .word, scheme: tagScheme, options: taggerOptions) { tag, tokenRange in
//            if let tag = tag {
//                tags.append(tag)
//            }
//            // Whether to continue.
//            return true
//        }
//        return tags
//    }

}
