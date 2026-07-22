//
//  Canto.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation

/// A ballad is grouped into sections, each containing a number of stanzas.
@Observable final class Canto {
    private let tag: LinguisticTag
	private let number: Int
	var stanzas: [Stanza]
    
	init(tag: LinguisticTag, stanzas: [Stanza], number: Int = 0) {
        self.tag = tag
        self.stanzas = stanzas
		self.number = number
	}
	
	var title: String {
		guard number > 0 else { return "Canto" }
		return "Canto \(romanNumeral(for: number))"
	}
	
	/// Whether the canto has been recited.
	/// Note that this means that at least one stanza has been recited.
    var isRecited: Bool {
		get {
			for stanza in stanzas {
				if stanza.isRecited {
					return true
				}
			}
			return false
		}
		set {
			for stanza in stanzas {
				stanza.isRecited = newValue
			}
		}
    }
	
	/// The rectited stanzas in the canto.
	var recitedStanzas: [Stanza] {
		stanzas.filter { $0.isRecited }
	}
    
    var duration: Duration {
        stanzas.reduce(.zero) { result, stanza in
            result + stanza.duration
        }
    }
}

// MARK: - Identifiable
extension Canto: Identifiable {
	
}
