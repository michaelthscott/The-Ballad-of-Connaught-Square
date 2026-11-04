//
//  NoteSelection.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 01/11/2026.
//

/// How an instrument's notes are selected: from patterns of intervals and durations of a given
/// width taken from some tunes, combined by some set operations.
struct NoteSelection: Sendable, Hashable {
    /// The tunes the patterns are taken from.
    var tunes: [TuneName]
    /// The number of intervals or durations in each pattern.
    var vectorWidth: UInt
    /// The ways the tunes' patterns are combined. Each time patterns are chosen, one of the
    /// combinations is picked at random.
    var operations: [Composer.SetOperation]

    init(tunes: [TuneName] = TuneName.allCases,
         vectorWidth: UInt = 3,
         operations: [Composer.SetOperation] = Composer.SetOperation.allCases) {
        self.tunes = tunes
        self.vectorWidth = vectorWidth
        self.operations = operations
    }

    /// Patterns three wide from every tune, combined in every way.
    static let standard = NoteSelection()
}
