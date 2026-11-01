//
//  VoiceNotation.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 01/11/2026.
//

/// The voices of a score: the roles that recite the ballad, and the rule for which role recites each part.
/// The roles are numbered from zero. The voice for each role is chosen in Settings.
struct VoiceNotation: Codable, Sendable, Equatable {
    var roles: [String]
    var rule: VoiceRule
}

/// Which role recites each part. A role number outside the roles wraps around them.
enum VoiceRule: Codable, Sendable, Equatable {
    /// The roles take turns, one part each, starting with the given role.
    case alternate(startingWith: Int)
    /// The role for the first, second, third… part of each line. Later parts take the last role.
    case byPartIndex(roles: [Int])
    /// The speaker written with each part in the ballad's lines.
    case asWritten
}

/// Works through a voice rule, part by part, keeping track of the turns.
struct VoiceTurns {
    let notation: VoiceNotation
    /// The number of parts that have taken a turn.
    private var turns = 0

    init(notation: VoiceNotation) {
        self.notation = notation
    }

    /// The role that recites the part, given its position in its line.
    mutating func role(for part: Part, at partIndex: Int) -> Int {
        defer { turns += 1 }
        let role: Int
        switch notation.rule {
        case .alternate(let first):
            role = first + turns
        case .byPartIndex(let roles):
            role = roles.indices.contains(partIndex) ? roles[partIndex] : roles.last ?? 0
        case .asWritten:
            role = part.speaker
        }
        return wrapped(role)
    }

    /// The role wrapped into the score's roles, or zero when there are none.
    private func wrapped(_ role: Int) -> Int {
        let count = notation.roles.count
        guard count > 0 else { return 0 }
        return (role % count + count) % count
    }
}
