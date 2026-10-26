//
//  Tagger.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/11/2023.
//

import Foundation
import NaturalLanguage
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ConnaughtSquare", category: "LinguisticTagger")

/// The errors thrown by ``LinguisticTagger``.
enum LinguisticTaggerError: LocalizedError {
    /// The tag scheme's assets aren't on this device for the language.
    case tagSchemeUnavailable(NLTagScheme, NLLanguage)
    /// The request for the tag scheme's assets didn't make the tag scheme available.
    case assetsUnavailable(NLTagScheme, NLLanguage)

    var errorDescription: String? {
        switch self {
        case let .tagSchemeUnavailable(tagScheme, language):
            "The \(tagScheme.rawValue) tag scheme for \(language.rawValue) isn't available on this device."
        case let .assetsUnavailable(tagScheme, language):
            "The assets for the \(tagScheme.rawValue) tag scheme for \(language.rawValue) couldn't be loaded onto this device."
        }
    }
}

/// A wrapper around `NSTagger` that limits the tags to name types and lexical tags. White space and punctuation are ignored. Names are joined.
struct LinguisticTagger {
    let tagScheme: NLTagScheme = .nameTypeOrLexicalClass
    let taggerOptions: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    let language: NLLanguage = .english

    /// Whether the framework lists the tag scheme for words in the tagger's language.
    private var isTagSchemeListed: Bool {
        NLTagger.availableTagSchemes(for: .word, language: language).contains(tagScheme)
    }

    /// Whether the tag scheme's assets are on this device for words in the tagger's language.
    /// Some run destinations, such as the simulators, lack them.
    ///
    /// The framework only lists a tag scheme once its assets have been loaded into the process,
    /// which tagging does, so a scheme that isn't listed is tagged with once before checking again.
    var isTagSchemeAvailable: Bool {
        if isTagSchemeListed {
            return true
        }
        logger.debug("The \(tagScheme.rawValue, privacy: .public) tag scheme isn't listed, so tagging to load its assets")
        _ = tags(for: "Man eats dog")
        return isTagSchemeListed
    }

    /// Checks that the tag scheme is available on this device.
    /// - Throws: ``LinguisticTaggerError/tagSchemeUnavailable(_:_:)`` when it isn't.
    func checkTagSchemeAvailability() throws(LinguisticTaggerError) {
        guard isTagSchemeAvailable else {
            throw LinguisticTaggerError.tagSchemeUnavailable(tagScheme, language)
        }
    }

    /// Asks the Natural Language framework to load the tag scheme's assets onto this device.
    /// - Throws: ``LinguisticTaggerError/assetsUnavailable(_:_:)`` when the tag scheme still isn't available, or the framework's error when the request fails.
    func requestAssets() async throws {
        let result: NLTagger.AssetsResult
        do {
            result = try await NLTagger.requestAssets(for: language, tagScheme: tagScheme)
        } catch {
            logger.error("The request for the tag scheme's assets failed: \(error, privacy: .public)")
            throw error
        }
        logger.debug("The request for the tag scheme's assets returned \(String(describing: result), privacy: .public)")
        guard result == .available, isTagSchemeAvailable else {
            throw LinguisticTaggerError.assetsUnavailable(tagScheme, language)
        }
    }

    /// Analyses the string into its constituent tags.
    /// - Parameter string: A string.
    /// - Returns: The linguistic tags for the string.
    /// - Throws: ``LinguisticTaggerError/tagSchemeUnavailable(_:_:)`` when the tag scheme isn't available on this device, as every word would otherwise be tagged as other word.
    func linguisticTagsArray(string: String) throws -> [LinguisticTag] {
        try checkTagSchemeAvailability()
        return tags(for: string)
    }

    /// Tags the string without checking that the tag scheme is available.
    private func tags(for string: String) -> [LinguisticTag] {
        let tagger = NLTagger(tagSchemes: [tagScheme])
        tagger.string = string
        let range = string.startIndex..<string.endIndex
        tagger.setLanguage(language, range: range)
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
