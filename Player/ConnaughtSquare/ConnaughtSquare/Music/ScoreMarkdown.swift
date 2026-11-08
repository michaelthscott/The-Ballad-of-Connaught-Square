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
    /// Reads a score written in Markdown, with its divisions grouped by the part of the ballad they
    /// belong to:
    ///
    ///     # The Ballad of Connaught Square
    ///
    ///     ## Stanza
    ///
    ///     ### Later line
    ///
    ///     - Violin, Cello: 0s–5s
    ///     - Viola: 0s–5s, 5s–end+1s at 60%
    ///     - Recite: 5.5s
    ///
    ///     ### Intermission
    ///
    ///     - Violin, Viola, Cello: 0s–7s
    ///     - Rest: 7s–8s
    ///
    /// The title comes first. Then come the groups, each a `##` heading: `Ballad`, with its `Title`
    /// and `Introduction`; `Canto`, with its `Title` and `Intermission`; `Stanza`, with its
    /// `First line`, `Later line` and `Intermission`; and `Line`, with its `Later parts`. Each
    /// division is a `###` heading under its group, and a list of what plays when it begins, like a
    /// cue sheet. The groups and their divisions can come in any order. A line starting with `>`,
    /// such as `> Plays before the ballad.`, describes what's around it and is otherwise skipped,
    /// so it can go anywhere.
    ///
    /// The introduction is played before the ballad, a canto intermission after each canto before the
    /// next, and a stanza intermission after each stanza before the next in the same canto, each in
    /// full with nothing recited in it. An intermission lasts until its last
    /// instrument stops, or until the end of a rest written after that, such as `Rest: 7s–8s`. The
    /// stanza's first line then follows. The ballad's title appears as the performance starts,
    /// before the introduction, and where a canto begins its title appears after any intermission,
    /// before the first line. Each title can rest after it with a `Title` that lists only rests,
    /// such as `Rest: 0s–2s`. Without one, what comes next follows the title straight away.
    ///
    /// Each of the others says once when the part starts being recited, such as
    /// `Recite: 5.5s`. Every other item names some instruments, then the stretches of time they play, such as `0s–5s`, each at
    /// full volume unless written with a percentage, such as `at 60%`. A time such as `5s` is counted
    /// from the start of the division, `end` is when the recitation finishes, and `end+1s` a second
    /// after that. Each instrument plays one unbroken melody through its stretches, picking it up
    /// again after a gap, so an instrument is named only once in a division. Written with
    /// `continues`, such as `Viola continues: 0s–end`, the instruments carry on the melodies they
    /// played in the part before, unless an intermission came between. Every instrument selects
    /// its notes in the standard way. The part's turn ends once the recitation and every instrument
    /// have finished.
    init(markdown: String) throws {
        var reader = ScoreReader()
        for (offset, line) in markdown.components(separatedBy: .newlines).enumerated() {
            try reader.read(line.trimmingCharacters(in: .whitespaces), at: offset + 1)
        }
        self = try reader.score()
    }
}

/// The divisions of the ballad that a score gives an intermission or an interlude, in the order
/// they're written.
private enum Division: CaseIterable {
    case balladTitle
    case introduction
    case cantoTitle
    case canto
    case firstLine
    case line
    case stanza
    case part

    /// The groups the divisions are written under, as their `##` headings are written.
    static let groups = ["Ballad", "Canto", "Stanza", "Line"]

    /// The group the division is written under.
    var group: String {
        switch self {
        case .balladTitle, .introduction: "Ballad"
        case .cantoTitle, .canto: "Canto"
        case .firstLine, .line, .stanza: "Stanza"
        case .part: "Line"
        }
    }

    /// The division's `###` heading, under its group.
    var heading: String {
        switch self {
        case .balladTitle, .cantoTitle: "Title"
        case .introduction: "Introduction"
        case .canto, .stanza: "Intermission"
        case .firstLine: "First line"
        case .line: "Later line"
        case .part: "Later parts"
        }
    }

    /// The division's name in messages, such as `Stanza first line`.
    var name: String {
        "\(group) \(heading.lowercased())"
    }

    /// Whether the division has an intermission, with nothing recited, rather than an interlude.
    /// A title counts as one, though it only rests.
    var isIntermission: Bool {
        switch self {
        case .introduction, .balladTitle, .canto, .cantoTitle, .stanza:
            true
        case .firstLine, .line, .part:
            false
        }
    }

    /// Whether the division is the rest after a title appears, so it has only rests.
    var isTitle: Bool {
        self == .balladTitle || self == .cantoTitle
    }
}

/// Reads a score line by line, keeping track of the group and division it's in.
private struct ScoreReader {
    private var title: String?
    private var interludes: [Division: Interlude] = [:]
    /// The groups read so far, the current one last.
    private var groups: [String] = []
    /// The division being read, or `nil` before the current group's first.
    private var division: Division?
    /// Whether the current division says when the part is recited.
    private var isRecited = false
    /// The instruments already named in the current division.
    private var instruments: Set<InstrumentName> = []
    /// The end of the last rest in each intermission.
    private var rests: [Division: Double] = [:]
    private var lineNumber = 0

    mutating func read(_ line: String, at lineNumber: Int) throws {
        self.lineNumber = lineNumber
        if line.isEmpty || line.hasPrefix(">") {
            // A blank line, or a description written as a quote, which the reader skips.
            return
        } else if let title = line.dropping(prefix: "# ") {
            guard self.title == nil else { throw error("The score has only one title") }
            self.title = title
        } else if let heading = line.dropping(prefix: "### ") {
            try begin(heading)
        } else if let group = line.dropping(prefix: "## ") {
            try beginGroup(group)
        } else if let item = line.dropping(prefix: "- ") {
            guard let division else { throw error("A list must follow a \"###\" heading") }
            try cue(item, in: division)
        } else {
            throw error("Expected a heading or a list item, not \"\(line)\"")
        }
    }

    func score() throws -> Score {
        guard let title else { throw ScoreError(line: nil, message: "The score has no title") }
        if let division, !division.isIntermission, !isRecited {
            throw ScoreError(line: nil, message: "\"\(division.name)\" doesn't say when to recite, such as \"Recite: 1s\"")
        }
        return Score(title: title,
                     balladTitleRest: rests[.balladTitle] ?? 0,
                     introduction: try intermission(.introduction),
                     canto: try intermission(.canto),
                     cantoTitleRest: rests[.cantoTitle] ?? 0,
                     stanza: try intermission(.stanza),
                     firstLine: try interlude(.firstLine),
                     line: try interlude(.line),
                     part: try interlude(.part))
    }

    private func interlude(_ division: Division) throws -> Interlude {
        guard let interlude = interludes[division] else {
            throw ScoreError(line: nil, message: "The score has no \"\(division.heading)\" under \"\(division.group)\"")
        }
        return interlude
    }

    private func intermission(_ division: Division) throws -> Intermission {
        Intermission(tracks: try interlude(division).tracks, seconds: rests[division])
    }

    /// Begins a group of divisions, such as `## Stanza`.
    private mutating func beginGroup(_ group: String) throws {
        guard title != nil else { throw error("The score must begin with its title") }
        try finishDivision()
        guard Division.groups.contains(group) else {
            let groups = Division.groups.map { "\"\($0)\"" }.joined(separator: ", ")
            throw error("\"\(group)\" isn't one of \(groups)")
        }
        guard !groups.contains(group) else { throw error("The score already has \"\(group)\"") }
        groups.append(group)
        division = nil
    }

    /// Begins a division in the current group, such as `### First line`.
    private mutating func begin(_ heading: String) throws {
        guard let group = groups.last else {
            throw error("\"\(heading)\" must come under a group, such as \"## Stanza\"")
        }
        try finishDivision()
        let divisions = Division.allCases.filter { $0.group == group }
        guard let division = divisions.first(where: { $0.heading == heading }) else {
            let headings = divisions.map { "\"\($0.heading)\"" }.joined(separator: ", ")
            throw error("\"\(heading)\" isn't one of \(headings) under \"\(group)\"")
        }
        guard interludes[division] == nil else { throw error("\"\(group)\" already has \"\(heading)\"") }
        self.division = division
        interludes[division] = Interlude()
        isRecited = false
        instruments = []
    }

    /// Checks that the division being read says when to recite, if it's recited.
    private func finishDivision() throws {
        if let division, !division.isIntermission, !isRecited {
            throw error("\"\(division.name)\" doesn't say when to recite, such as \"Recite: 1s\"")
        }
    }

    /// Reads a cue in a division: when the part is recited, such as `Recite: 5.5s`, a rest in an
    /// intermission, such as `Rest: 7s–8s`, or what some instruments play, such as
    /// `Viola: 0s–5s, 5s–end+1s at 60%`.
    private mutating func cue(_ item: String, in division: Division) throws {
        guard let colon = item.range(of: ": ") else {
            throw error("Expected \"Recite: 1s\" or instruments and when they play, such as \"Viola: 0s–5s\", not \"\(item)\"")
        }
        let label = String(item[..<colon.lowerBound])
        let times = String(item[colon.upperBound...])
        if label == "Recite" {
            guard !division.isIntermission else {
                throw error("Nothing is recited in \"\(division.name)\", an intermission; \"Stanza first line\" opens the part after it")
            }
            guard !isRecited else { throw error("\"\(division.name)\" already says when to recite") }
            guard case .seconds(let seconds) = try moment(times) else {
                throw error("The recitation starts at a time from the start of the division, such as \"Recite: 1s\"")
            }
            interludes[division]?.recitationStart = seconds
            isRecited = true
        } else if label == "Rest" {
            guard division.isIntermission else {
                throw error("A rest is written only in an intermission; \"\(division.name)\" lasts until its part and instruments have finished")
            }
            for text in times.components(separatedBy: ", ") {
                let rest = try stretch(text)
                guard rest.volume == 1 else { throw error("A rest has no volume") }
                try checkIntermission(rest, in: division)
                if case .seconds(let end) = rest.end {
                    rests[division] = max(rests[division] ?? 0, end)
                }
            }
        } else {
            var label = label
            var continues = false
            if let names = label.dropping(suffix: " continues") {
                guard !division.isIntermission else {
                    throw error("An intermission always starts its melodies afresh, so nothing in \"\(division.name)\" continues")
                }
                label = names
                continues = true
            }
            guard !division.isTitle else {
                throw error("Only rests are written in \"\(division.name)\", such as \"Rest: 0s–2s\"")
            }
            let names = try label.components(separatedBy: ", ").map(instrument)
            for name in names {
                guard instruments.insert(name).inserted else {
                    throw error("\(name) already plays in \"\(division.name)\"; give it all its times on one line")
                }
            }
            var stretches: [Stretch] = []
            for text in times.components(separatedBy: ", ") {
                let stretch = try stretch(text)
                try checkIntermission(stretch, in: division)
                if let previous = stretches.last, previous.end != stretch.start, !previous.end.isBefore(stretch.start) {
                    throw error("\"\(text)\" must start after the time before it ends, \(previous.end)")
                }
                stretches.append(stretch)
            }
            interludes[division]?.tracks.append(Track(instruments: names, stretches: stretches, continues: continues))
        }
    }

    /// Checks that a stretch in an intermission doesn't count from the end of a recitation, as there's none.
    private func checkIntermission(_ stretch: Stretch, in division: Division) throws {
        guard division.isIntermission else { return }
        if case .afterRecitation = stretch.end {
            throw error("Nothing is recited in \"\(division.name)\", an intermission, so its times are from its start, not \"\(stretch.end)\"")
        }
    }

    /// Reads a stretch such as `0s–5s` or `5s–end+1s at 60%`.
    private func stretch(_ text: String) throws -> Stretch {
        var range = text
        var volume = 1.0
        if let at = text.range(of: " at ", options: .backwards) {
            range = String(text[..<at.lowerBound])
            volume = try self.volume(String(text[at.upperBound...]))
        }
        let ends = range.components(separatedBy: CharacterSet(charactersIn: "–-"))
        guard ends.count == 2 else {
            throw error("\"\(range)\" isn't a stretch of time, such as \"0s–5s\"")
        }
        let start = try moment(ends[0])
        let end = try moment(ends[1])
        guard start.isBefore(end) else {
            throw error("\"\(range)\" must end after it starts")
        }
        return Stretch(start: start, end: end, volume: volume)
    }

    /// Reads a time such as `5.5s`, counted from the start of the division, or `end` or `end+1s`,
    /// counted from the end of the recitation.
    private func moment(_ text: String) throws -> Moment {
        if text == "end" {
            return .endOfRecitation
        } else if let after = text.dropping(prefix: "end+") {
            return .afterRecitation(seconds: try seconds(after))
        } else {
            return .seconds(try seconds(text))
        }
    }

    /// Reads a number of seconds such as `7s` or `0.5s`.
    private func seconds(_ text: String) throws -> Double {
        guard let number = text.dropping(suffix: "s"), let seconds = Double(number), seconds.isFinite, seconds >= 0 else {
            throw error("\"\(text)\" isn't a time in seconds, such as \"5s\", \"end\" or \"end+1s\"")
        }
        return seconds
    }

    /// Reads a volume such as `60%`.
    private func volume(_ text: String) throws -> Double {
        guard let number = text.dropping(suffix: "%"), let percent = Double(number), (0...100).contains(percent) else {
            throw error("A volume must be a percentage from 0% to 100%, not \"\(text)\"")
        }
        return percent / 100
    }

    /// Reads an instrument such as `Viola`.
    private func instrument(_ name: String) throws -> InstrumentName {
        guard let instrument = InstrumentName.allCases.first(where: { $0.description == name }) else {
            throw error("No instrument named \"\(name)\"")
        }
        return instrument
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
