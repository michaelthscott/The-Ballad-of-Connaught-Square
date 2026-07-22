//
//  Stanza.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation
import NaturalLanguage

/// A stanza in a ballad is a grouping of one to four lines.
@Observable final class Stanza {
    var lines: ArraySlice<Line>
    
    init(lines: ArraySlice<Line>) {
        self.lines = lines
    }
	
	/// Whether the stanza has been recited.
	/// Note that this means that at least one line has been recited.
	var isRecited: Bool {
		get {
			for line in lines {
				if line.isRecited {
					return true
				}
			}
			return false
		}
		set {
			for line in lines {
				line.isRecited = newValue
			}
		}
	}
	
	/// The recited lines of the stanza.
	var recitedLines: [Line] {
		lines.filter { $0.isRecited }
	}
	
    var duration: Duration {
        lines.reduce(.zero) { result, line in
            result + line.duration
        }
    }

    /// Tests whether the first line of the stanza starts with a linguistic tag.
    /// - Parameter tag: The linguistic tag.
    /// - Returns: The result of the test.
    func startsWith(tag: LinguisticTag) -> Bool {
        guard let first = lines.first else {
            return false
        }
		return first.startsWith(tag: tag)
    }
    
    
}

// MARK: - Identifiable
extension Stanza: Identifiable {
	
}
