//
//  CorrectPronunciation.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 24/12/2023.
//

import Foundation

/// An IPA string specifying a correct pronunciation.
struct CorrectPronunciation: Codable, Equatable {
	let ipa: String
	let location: Int
	let length: Int
}
