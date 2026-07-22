//
//  RomanNumerals.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 19/12/2023.
//

import Foundation

// TODO: Write some tests.

func romanNumeral(for number: Int) -> String {
	guard number > 0 && number < 4000 else {
		fatalError("Number must be between 1 and 3999")
	}
	var string = ""
	let arabicNumbers = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	let romanLetters  = [ "M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
	var value = number
	for (arabic, roman) in zip(arabicNumbers, romanLetters) {
		let repeats = value / arabic
		string += String(repeating: roman, count: repeats)
		value = value % arabic
	}
	return string
}
