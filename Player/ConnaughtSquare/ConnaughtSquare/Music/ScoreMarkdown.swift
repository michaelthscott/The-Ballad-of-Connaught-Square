//
//  ScoreMarkdown.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 04/11/2026.
//

import Foundation

/// A mistake in a score written in Markdown.
struct ScoreError: Error, CustomStringConvertible, Equatable {
    /// The line of the score the mistake is on, counting from 1, or `nil` when it's in the score as a whole.
    let line: Int?
    let message: String

    var description: String {
        line.map { "Line \($0): \(message)" } ?? message
    }
}

extension Score {
    /// Reads a score written in Markdown, in the order it's performed:
    ///
    ///     # The Ballad of Connaught Square
    ///
    ///     ## Voices
    ///
    ///     - First
    ///     - Second
    ///
    ///     ## Each stanza
    ///
    ///     - Violin, Viola, Cello for 7s
    ///     - Rest for 1s
    ///     - Recite, with Viola at 60%
    ///
    /// The title comes first, then the voices, each part being recited by the next of them in turn,
    /// starting with the first. Then come the introduction, each canto, each stanza, each line and
    /// each later part, each a list of what plays in turn before the part, ending with `Recite`.
    /// What follows `Recite, with` plays under the part, its steps separated by `, then`.
    ///
    /// An instrument plays at full volume unless written with a percentage, such as `Viola at 60%`.
    /// Music plays for the seconds written, such as `for 7s`, or under the part without them, for as
    /// long as the part takes to recite. Every instrument selects its notes in the standard way.
    init(markdown: String) throws {
        var reader = ScoreReader()
        for (offset, line) in markdown.components(separatedBy: .newlines).enumerated() {
            try reader.read(line.trimmingCharacters(in: .whitespaces), at: offset + 1)
        }
        self = try reader.score()
    }
}

/// The divisions of the ballad that a score gives an interlude, as their headings are written.
private enum Division: String, CaseIterable {
    case introduction = "Introduction"
    case canto = "Each canto"
    case stanza = "Each stanza"
    case line = "Each line"
    case part = "Each later part"
}

/// Reads a score line by line, keeping track of the section it's in.
private struct ScoreReader {
    private enum Section: Equatable {
        case voices
        case division(Division)
    }

    private var title: String?
    private var roles: [String] = []
    private var interludes: [Division: Interlude] = [:]
    private var sections: [Section] = []
    /// Whether the current division's list has reached `Recite`.
    private var isRecited = false
    private var lineNumber = 0

    mutating func read(_ line: String, at lineNumber: Int) throws {
        self.lineNumber = lineNumber
        if line.isEmpty {
            return
        } else if let title = line.dropping(prefix: "# ") {
            guard self.title == nil else { throw error("The score has only one title") }
            self.title = title
        } else if let heading = line.dropping(prefix: "## ") {
            try begin(heading)
        } else if let item = line.dropping(prefix: "- ") {
            switch sections.last {
            case .voices:
                guard !roles.contains(item) else { throw error("\"\(item)\" is already a voice") }
                roles.append(item)
            case .division(let division):
                try step(item, in: division)
            case nil:
                throw error("A list must follow a heading")
            }
        } else {
            throw error("Expected a heading or a list item, not \"\(line)\"")
        }
    }

    func score() throws -> Score {
        guard let title else { throw ScoreError(line: nil, message: "The score has no title") }
        guard !roles.isEmpty else { throw ScoreError(line: nil, message: "The score has no voices") }
        if case .division(let division) = sections.last, !isRecited {
            throw ScoreError(line: nil, message: "\"\(division.rawValue)\" doesn't end with Recite")
        }
        return Score(title: title,
                     voices: VoiceNotation(roles: roles),
                     introduction: try interlude(.introduction),
                     canto: try interlude(.canto),
                     stanza: try interlude(.stanza),
                     line: try interlude(.line),
                     part: try interlude(.part))
    }

    private func interlude(_ division: Division) throws -> Interlude {
        guard let interlude = interludes[division] else {
            throw ScoreError(line: nil, message: "The score has no \"\(division.rawValue)\"")
        }
        return interlude
    }

    private mutating func begin(_ heading: String) throws {
        guard title != nil else { throw error("The score must begin with its title") }
        if case .division(let division) = sections.last, !isRecited {
            throw error("\"\(division.rawValue)\" doesn't end with Recite")
        }
        let section: Section
        if heading == "Voices" {
            section = .voices
        } else if let division = Division(rawValue: heading) {
            section = .division(division)
        } else {
            let headings = ["Voices"] + Division.allCases.map(\.rawValue)
            throw error("\"\(heading)\" isn't one of \(headings.map { "\"\($0)\"" }.joined(separator: ", "))")
        }
        guard !sections.contains(section) else { throw error("The score already has \"\(heading)\"") }
        sections.append(section)
        if case .division(let division) = section {
            interludes[division] = Interlude()
            isRecited = false
        }
    }

    /// Reads a step of a division: what plays before the part, or the part's recitation and what plays under it.
    private mutating func step(_ item: String, in division: Division) throws {
        guard !isRecited else {
            throw error("Nothing follows Recite; write what plays under the part after \"Recite, with\"")
        }
        if item == "Recite" {
            isRecited = true
        } else if let under = item.dropping(prefix: "Recite, with ") {
            let segments = try under.components(separatedBy: ", then ").map { try segment($0, isBefore: false) }
            interludes[division]?.under = segments
            isRecited = true
        } else {
            let segment = try segment(item, isBefore: true)
            interludes[division]?.before.append(segment)
        }
    }

    /// Reads `Rest for 1s`, or instruments such as `Violin, Viola at 60% for 5s`.
    private func segment(_ text: String, isBefore: Bool) throws -> Segment {
        var body = text
        var seconds: Double?
        if let range = text.range(of: " for ", options: .backwards) {
            body = String(text[..<range.lowerBound])
            seconds = try length(String(text[range.upperBound...]))
        }
        if body == "Rest" {
            guard let seconds else { throw error("A rest needs a length, such as \"Rest for 1s\"") }
            return .rest(seconds: seconds)
        }
        if isBefore && seconds == nil {
            throw error("Music before the part needs a length, such as \"\(body) for 5s\"")
        }
        let instruments = try body.components(separatedBy: ", ").map(instrumentPart)
        return .music(Passage(seconds: seconds, instruments: instruments))
    }

    /// Reads a length such as `7s` or `0.5s`.
    private func length(_ text: String) throws -> Double {
        guard let number = text.dropping(suffix: "s"), let seconds = Double(number), seconds.isFinite, seconds > 0 else {
            throw error("\"\(text)\" isn't a length in seconds, such as \"5s\"")
        }
        return seconds
    }

    /// Reads an instrument such as `Viola` or `Viola at 60%`.
    private func instrumentPart(_ text: String) throws -> InstrumentPart {
        var name = text
        var volume = 1.0
        if let range = text.range(of: " at ", options: .backwards) {
            name = String(text[..<range.lowerBound])
            let percentage = String(text[range.upperBound...])
            guard let number = percentage.dropping(suffix: "%"), let percent = Double(number), (0...100).contains(percent) else {
                throw error("The volume of \(name) must be a percentage from 0% to 100%, not \"\(percentage)\"")
            }
            volume = percent / 100
        }
        guard let instrument = InstrumentName.allCases.first(where: { $0.description == name }) else {
            throw error("No instrument named \"\(name)\"")
        }
        return InstrumentPart(instrument: instrument, volume: volume)
    }

    private func error(_ message: String) -> ScoreError {
        ScoreError(line: lineNumber, message: message)
    }
}

private extension String {
    /// The rest of the string after the prefix, or `nil` if it doesn't start with it.
    func dropping(prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }

    /// The string before the suffix, or `nil` if it doesn't end with it.
    func dropping(suffix: String) -> String? {
        hasSuffix(suffix) ? String(dropLast(suffix.count)) : nil
    }
}
