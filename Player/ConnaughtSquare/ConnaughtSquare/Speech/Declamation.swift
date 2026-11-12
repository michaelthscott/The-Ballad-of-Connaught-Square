//
//  Declamation.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 11/11/2026.
//

import Foundation
import AVFoundation

/// Where a part comes in its line, which decides how its last phrase ends.
enum PartPosition: Sendable, Equatable {
    /// The part is followed by another in the same line.
    case caesura
    /// The part ends its line.
    case lineEnd
}

/// The punctuation that ends a word, which shapes the pause and pitch after it.
enum WordMark: Sendable, Equatable {
    case none
    case comma
    case fullStop
    case question
    case exclamation
    /// A single `…`, which marks breaking off, trailing off or hesitating.
    case ellipsis

    init(ending word: some StringProtocol) {
        switch word.last {
        case "…": self = .ellipsis
        case ",": self = .comma
        case ".": self = .fullStop
        case "?": self = .question
        case "!": self = .exclamation
        default: self = .none
        }
    }
}

/// The tunables of a declamation: how far the pitch moves, how much stress stands out, and how
/// long each kind of pause lasts. Pitches are in semitones, and rates multiply the voice's default rate.
struct DeclamationStyle: Sendable, Equatable {
    /// How far the pitch rises to the first stressed word.
    var contourDepth: Double = 3
    /// How far the pitch drifts down from the first stressed word to the last word.
    var declination: Double = 2
    /// How far the last word falls at the end of a line ending with a full stop or exclamation.
    var finalFall: Double = 3
    /// How far a question to be answered yes or no rises from its last stressed word to its end.
    var finalRise: Double = 3
    /// How far a stressed word rises above the contour.
    var stressBoost: Double = 1.5
    /// The rate of a stressed word, relative to the base rate, slowed so that it stands out.
    var stressRate: Float = 0.9
    /// The rate of the declamation, relative to the voice's default rate.
    var baseRate: Float = 0.7
    /// The pause after a part that's followed by another in its line.
    var caesuraPause: Duration = .milliseconds(250)
    /// The pause after a part that ends its line.
    var lineEndPause: Duration = .milliseconds(500)
    /// The pause after a part that ends with `…`, trailing or breaking off.
    var trailingEllipsisPause: Duration = .milliseconds(700)
    /// The pause at a `…` within a part, a hesitation.
    var hesitationPause: Duration = .milliseconds(450)
    /// The pause at a comma.
    var commaPause: Duration = .milliseconds(200)
    /// The note the voice's natural pitch is taken to be, which the baseline is measured from.
    var reference: NoteValue = .c3
    /// How much of the baseline's distance from the reference the pitch follows. The music spans
    /// more than an octave, which would take a voice far from its natural register.
    var baselineWeight: Double = 0.5

    static let standard = DeclamationStyle()
}

extension DeclamationStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case contourDepth, declination, finalFall, finalRise, stressBoost, stressRate, baseRate
        case caesuraPause, lineEndPause, trailingEllipsisPause, hesitationPause, commaPause
        case reference, baselineWeight
    }

    /// Decodes the style, taking the standard value for anything not stored, so that a style
    /// saved before a tunable was added keeps its other values.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let standard = DeclamationStyle.standard
        func value<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? container.decodeIfPresent(T.self, forKey: key)) ?? fallback
        }
        contourDepth = value(.contourDepth, standard.contourDepth)
        declination = value(.declination, standard.declination)
        finalFall = value(.finalFall, standard.finalFall)
        finalRise = value(.finalRise, standard.finalRise)
        stressBoost = value(.stressBoost, standard.stressBoost)
        stressRate = value(.stressRate, standard.stressRate)
        baseRate = value(.baseRate, standard.baseRate)
        caesuraPause = value(.caesuraPause, standard.caesuraPause)
        lineEndPause = value(.lineEndPause, standard.lineEndPause)
        trailingEllipsisPause = value(.trailingEllipsisPause, standard.trailingEllipsisPause)
        hesitationPause = value(.hesitationPause, standard.hesitationPause)
        commaPause = value(.commaPause, standard.commaPause)
        reference = value(.reference, standard.reference)
        baselineWeight = value(.baselineWeight, standard.baselineWeight)
    }
}

extension DeclamationStyle {
    /// Where the listener's style is kept between launches.
    static let defaultsKey = "DeclamationStyle"

    /// The style saved in the defaults, or the standard style if none has been saved or it can't be read.
    static func saved(in defaults: UserDefaults = .standard) -> DeclamationStyle {
        guard let data = defaults.data(forKey: defaultsKey),
              let style = try? JSONDecoder().decode(DeclamationStyle.self, from: data) else {
            return .standard
        }
        return style
    }

    /// Saves the style in the defaults, for the next launch.
    func save(in defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}

/// A word as it's to be declaimed.
struct DeclaimedWord: Sendable, Equatable {
    /// The word as it's spoken, with its punctuation.
    let text: String
    /// The IPA of any correct pronunciation that covers the word.
    let ipa: String?
    let isStressed: Bool
    let mark: WordMark
    /// The pitch in semitones from the declamation's baseline.
    var pitch: Double
    /// The rate, relative to the voice's default rate.
    var rate: Float
    /// The silence after the word.
    var pauseAfter: Duration
}

/// A part shaped for a theatrical recitation, with stressed words slowed so that they stand
/// out, pauses at punctuation and at the end of the part, and a contour that rises to the first
/// stress, drifts down, and ends according to the part's last mark and where it comes in its line.
///
/// A `…` ending the part suspends it, holding the pitch rather than letting it fall, before a long
/// pause; a `…` within the part is a hesitation, with the pitch held across it. Through the voices,
/// `…` is the only mark that sounds different from a full stop at the end of a part, so the other
/// marks' pauses and pitches come from here rather than from the voice.
struct Declamation: Sendable, Equatable {
    /// The note the part's pitch centres on, from the music it's recited over. It's set once the
    /// music has been composed, which is sized by how long the declamation is expected to take.
    var baseline: NoteValue?
    /// The tunables the part was shaped with, which also place its pitch against the voice.
    let style: DeclamationStyle
    let position: PartPosition
    var words: [DeclaimedWord]

    /// Words that are left unstressed, however the lexicon stresses them, so that the stress
    /// falls on the words that carry the meaning. "a" before a `…` especially must stay the
    /// article rather than becoming the letter.
    static let unstressedWords: Set<String> = [
        "a", "an", "the", "and", "but", "or", "nor", "of", "to", "in", "on", "at", "by", "for",
        "with", "from", "as", "if", "than", "is", "am", "are", "was", "were", "be", "been",
        "it", "its", "it's", "i", "i'm", "i'll", "i've", "i'd", "you", "he", "she", "we", "they",
        "you're", "we're", "they're", "he's", "she's", "you'll", "we'll", "they'll", "you've", "we've", "they've",
        "me", "him", "her", "us", "them", "my", "your", "his", "our", "their",
        "do", "does", "did", "have", "has", "had", "can", "will", "would", "could", "should",
        "shall", "may", "might", "must",
        // Fillers, which are heard as hesitations rather than words.
        "ah", "oh", "er", "erm", "um", "uh", "mmm",
    ]

    /// Shapes the part's string.
    /// - Parameters:
    ///   - string: The part's string.
    ///   - pronunciations: Correct pronunciations, by their ranges in the string.
    ///   - position: Where the part comes in its line.
    ///   - baseline: The note the part's pitch centres on, if there's music to take it from.
    ///   - style: The tunables.
    ///   - lexicon: Where the words' stresses are looked up.
    init(string: String,
         pronunciations: [CorrectPronunciation] = [],
         position: PartPosition,
         baseline: NoteValue? = nil,
         style: DeclamationStyle = .standard,
         lexicon: Lexicon = .shared) {
        self.baseline = baseline
        self.style = style
        self.position = position
        let tokens = string.split(whereSeparator: \.isWhitespace)
        var words = tokens.map { token in
            let range = NSRange(token.startIndex..<token.endIndex, in: string)
            let ipa = pronunciations.first { pronunciation in
                NSIntersectionRange(range, NSRange(location: pronunciation.location, length: pronunciation.length)).length > 0
            }?.ipa
            let isStressed = Self.isStressed(token, in: lexicon)
            return DeclaimedWord(text: String(token),
                                 ipa: ipa,
                                 isStressed: isStressed,
                                 mark: WordMark(ending: token),
                                 pitch: 0,
                                 rate: isStressed ? style.baseRate * style.stressRate : style.baseRate,
                                 pauseAfter: .zero)
        }
        Self.shapeContour(&words, position: position, style: style)
        Self.placePauses(&words, position: position, style: style)
        self.words = words
    }

    /// Shapes the part, taking where it comes in the line from the line.
    init(part: Part, in line: Line, baseline: NoteValue? = nil, style: DeclamationStyle = .standard, lexicon: Lexicon = .shared) {
        let position: PartPosition = line.parts.last === part ? .lineEnd : .caesura
        self.init(string: part.string, pronunciations: part.pronunciations, position: position,
                  baseline: baseline, style: style, lexicon: lexicon)
    }

    /// The word without its punctuation, lowercased, keeping apostrophes within it.
    static func bare(_ word: some StringProtocol) -> String {
        word.trimmingCharacters(in: .punctuationCharacters.subtracting(CharacterSet(charactersIn: "'"))).lowercased()
    }

    /// Whether the word carries a stress. Function words never do. Other words are stressed when
    /// the lexicon gives them a primary stress, or when the lexicon doesn't know them, as is
    /// usually so of names.
    static func isStressed(_ word: some StringProtocol, in lexicon: Lexicon) -> Bool {
        let bare = bare(word)
        guard !bare.isEmpty, !unstressedWords.contains(bare) else { return false }
        guard let entry = lexicon.word(bare) else { return true }
        return entry.syllables.contains(where: \.isStressed)
    }

    /// Rises to the first stressed word, drifts down to the last, lifts stressed words above the
    /// line, holds the pitch across marks within the part, then ends as the last mark says.
    private static func shapeContour(_ words: inout [DeclaimedWord], position: PartPosition, style: DeclamationStyle) {
        guard !words.isEmpty else { return }
        if isYesNoQuestion(words) {
            shapeQuestion(&words, style: style)
            return
        }
        let peak = words.firstIndex(where: \.isStressed) ?? 0
        let last = words.count - 1
        var line = words.indices.map { index -> Double in
            if index <= peak {
                return peak == 0 ? style.contourDepth : style.contourDepth * Double(index) / Double(peak)
            }
            return style.contourDepth - style.declination * Double(index - peak) / Double(last - peak)
        }
        // A hesitation or comma holds the pitch, so the word after it carries on where it left off.
        for index in words.indices.dropLast() where words[index].mark == .ellipsis || words[index].mark == .comma {
            line[index + 1] = line[index]
        }
        for index in words.indices {
            words[index].pitch = line[index] + (words[index].isStressed ? style.stressBoost : 0)
        }
        switch words[last].mark {
        case .ellipsis:
            // Suspended: the last word stays at the pitch of the line before it, without a fall.
            if last > 0 {
                words[last].pitch = max(words[last].pitch, line[last - 1])
            }
        case .exclamation:
            words[last].pitch += style.stressBoost
            if position == .lineEnd {
                words[last].pitch -= style.finalFall
            }
        case .fullStop, .none, .comma, .question:
            // A question that opens with a question word falls like a statement; one to be
            // answered yes or no has been shaped already.
            if position == .lineEnd {
                words[last].pitch -= style.finalFall
            }
        }
    }

    /// Words that open a question asking for information rather than a yes or no, which falls at
    /// its end like a statement.
    static let questionWords: Set<String> = ["what", "where", "when", "why", "who", "whom", "whose", "which", "how"]

    /// Whether the words ask a question to be answered yes or no: they end with a question mark,
    /// and don't open with a question word.
    static func isYesNoQuestion(_ words: [DeclaimedWord]) -> Bool {
        guard words.last?.mark == .question, let first = words.first else { return false }
        return !questionWords.contains(bare(first.text))
    }

    /// A question to be answered yes or no keeps a low, level head, so that no early word sounds
    /// like what's being asked about, then rises from its last stressed word to its end.
    private static func shapeQuestion(_ words: inout [DeclaimedWord], style: DeclamationStyle) {
        let last = words.count - 1
        let nucleus = words.lastIndex(where: \.isStressed) ?? last
        for index in words.indices {
            let stress = words[index].isStressed ? style.stressBoost : 0
            if index < nucleus {
                words[index].pitch = stress
            } else {
                // The rise starts on the nucleus and reaches its height on the last word.
                let progress = last == nucleus ? 1 : Double(index - nucleus) / Double(last - nucleus)
                words[index].pitch = stress + style.finalRise * progress
            }
        }
    }

    /// Pauses at the marks within the part, and after the part as its last mark and position say.
    private static func placePauses(_ words: inout [DeclaimedWord], position: PartPosition, style: DeclamationStyle) {
        guard let last = words.indices.last else { return }
        for index in words.indices.dropLast() {
            switch words[index].mark {
            case .ellipsis: words[index].pauseAfter = style.hesitationPause
            case .comma: words[index].pauseAfter = style.commaPause
            case .fullStop, .question, .exclamation: words[index].pauseAfter = style.commaPause * 2
            case .none: break
            }
        }
        let positionPause = position == .lineEnd ? style.lineEndPause : style.caesuraPause
        words[last].pauseAfter = words[last].mark == .ellipsis ? max(positionPause, style.trailingEllipsisPause) : positionPause
    }

    /// How far in semitones the baseline moves the part from the voice's natural pitch: the
    /// baseline's distance from the style's reference note, as much of it as the style follows,
    /// or zero when there's no baseline.
    var baselineOffset: Double {
        guard let baseline else { return 0 }
        return Double(Int(baseline.rawValue) - Int(style.reference.rawValue)) * style.baselineWeight
    }

    /// Each word's pitch in semitones from the voice's natural pitch: its pitch in the contour,
    /// moved by the baseline.
    var pitches: [Double] {
        let offset = baselineOffset
        return words.map { $0.pitch + offset }
    }

    /// How much longer speech takes at a rate than at the voice's default rate. Slowing the rate
    /// slows the voices much less than in proportion: measured on 11/11/2026, a rate of 70% made
    /// speech only about a sixth longer, which this follows.
    static func lengthening(atRate rate: Float) -> Double {
        pow(Double(max(rate, 0.1)), -0.43)
    }

    /// How long the declamation is expected to take: the words at the base rate, and the pauses.
    /// The music around the part is composed to last about this long.
    var expectedDuration: Duration {
        let speaking = words.map(\.text).joined(separator: " ").speakingTime * Self.lengthening(atRate: style.baseRate)
        return words.reduce(speaking) { $0 + $1.pauseAfter }
    }

    /// The part as plain text, with each word's correct pronunciation on that word, for speaking
    /// it without the declamation's shaping.
    var attributedString: NSAttributedString {
        let string = NSMutableAttributedString()
        for (index, word) in words.enumerated() {
            if index > 0 {
                string.append(NSAttributedString(string: " "))
            }
            let text = NSMutableAttributedString(string: word.text)
            let range = (word.text as NSString).range(of: Self.bare(word.text), options: .caseInsensitive)
            if let ipa = word.ipa, range.location != NSNotFound {
                text.addAttribute(NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute), value: ipa, range: range)
            }
            string.append(text)
        }
        return string
    }

    /// The note the music plays most often across the events, the lowest such note when several tie,
    /// or `nil` when the events have no notes.
    static func baseline(for events: [Event]) -> NoteValue? {
        var counts: [NoteValue: Int] = [:]
        for event in events {
            for note in event.notes.elements {
                counts[note.value, default: 0] += 1
            }
        }
        return counts.max { lhs, rhs in
            lhs.value == rhs.value ? lhs.key > rhs.key : lhs.value < rhs.value
        }?.key
    }
}

extension Declamation: CustomStringConvertible {
    /// A word-by-word table: the word, whether it's stressed, its pitch, rate and pause after it.
    var description: String {
        words.map { word in
            let pitch = word.pitch.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always()))
            let rate = word.rate.formatted(.number.precision(.fractionLength(2)))
            let pause = word.pauseAfter == .zero ? "" : " pause \(word.pauseAfter.formatted(.units(allowed: [.milliseconds])))"
            return "\(word.text.padding(toLength: 14, withPad: " ", startingAt: 0)) \(word.isStressed ? "ˈ" : " ") \(pitch) st  ×\(rate)\(pause)"
        }.joined(separator: "\n")
    }
}
