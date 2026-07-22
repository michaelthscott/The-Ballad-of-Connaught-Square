//
//  NoteInterval.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 07/12/2023.
//

enum NoteInterval {
   case rising(by: Int)
   case falling(by: Int)
   case level

   init(from: Note, to: Note) {
        let difference = Int(to.value.rawValue) - Int(from.value.rawValue)
        switch difference {
        case ..<0:
           self = .falling(by: abs(difference))
        case 0:
           self = .level
        default:
           self = .rising(by: difference)
        }
    }
}

extension NoteInterval: Equatable {
}

extension NoteInterval: Comparable {
}

extension NoteInterval: Hashable {
}

extension NoteInterval: Codable {
}
