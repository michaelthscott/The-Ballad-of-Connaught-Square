//
//  NoteDuration.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 07/12/2023.
//

// TODO: Is this microseconds?

/// The duration of a note in standard musical terminology.
enum NoteDuration: UInt32 {
    case breve = 8000000
    case semibreve = 4000000
    case dottedMinim = 3000000
    case minim = 2000000
    case dottedCrotchet = 1500000
    case crotchet = 1000000
    case quaver = 500000
	
	var duration: Duration {
		.seconds(Double(rawValue) / 1000000.00)
	}
    
    var microseconds: Duration {
        .microseconds(rawValue)
    }
}

extension NoteDuration: CaseIterable {
    static var randomDuration: NoteDuration {
        Self.allCases.randomElement()!
    }
}

extension NoteDuration: Comparable {
    public static func < (lhs: NoteDuration, rhs: NoteDuration) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension NoteDuration: Codable {
	
}

extension NoteDuration: CustomStringConvertible {
	var description: String {
		switch self {
		case .breve:
			return "Breve"
		case .semibreve:
			return "Semibreve"
		case .dottedMinim:
			return "Dotted Minim"
		case .minim:
			return "Minim"
		case .dottedCrotchet:
			return "Dotted Crotchet"
		case .crotchet:
			return "Crotchet"
		case .quaver:
			return "Quaver"
		}
	}
}
