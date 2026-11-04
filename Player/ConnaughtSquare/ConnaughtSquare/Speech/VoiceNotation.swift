//
//  VoiceNotation.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 01/11/2026.
//

/// The roles that recite the ballad, taking turns one part each, starting with the first. The
/// roles are numbered from zero. The voice for each role is chosen in Settings.
struct VoiceNotation: Sendable, Equatable {
    var roles: [String]

    /// The two roles the ballad is recited in.
    static let standard = VoiceNotation(roles: ["First", "Second"])
}

/// Keeps track of the roles' turns, part by part.
struct VoiceTurns {
    let notation: VoiceNotation
    /// The number of parts that have taken a turn.
    private var turns = 0

    init(notation: VoiceNotation) {
        self.notation = notation
    }

    /// The role that recites the next part, after the last role going back to the first, or zero
    /// when there are no roles.
    mutating func nextRole() -> Int {
        defer { turns += 1 }
        let count = notation.roles.count
        return count > 0 ? turns % count : 0
    }
}
