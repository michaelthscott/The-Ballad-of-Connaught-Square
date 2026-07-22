//
//  TagSortOrder.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 24/10/2023.
//

import Foundation

// Used to specify ways of ordering tags.
enum TagSortOrder: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case ascending = "Ascending"
    case descending = "Descending"
    case invert = "Invert"
    case random = "Random"
    case choose = "Choose" // This means that the sort order has yet to be defined.

    var id: Self { self }
    var description: String { rawValue }
}
