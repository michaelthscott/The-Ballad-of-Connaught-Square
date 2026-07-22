//
//  LinePair.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 30/12/2023.
//

struct LinePair {
	let first: Line
	let second: Line
	
	var availableRhymes: [RhymeType] {
		var rhymeTypes: [RhymeType] = []
		for rhymeType in RhymeType.allCases {
			if rhymeType.linesRhyme(self) {
				rhymeTypes.append(rhymeType)
			}
		}
		return rhymeTypes
	}
}

extension LinePair: CustomStringConvertible {
	var description: String {
		[first.string, second.string].joined(separator: ", ")
	}
}
