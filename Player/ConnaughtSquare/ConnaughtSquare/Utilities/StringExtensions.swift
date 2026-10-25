//
//  StringExtensions.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 20/01/2024.
//

import Foundation

extension String {
	/// The words, separated by runs of whitespace or newlines. Punctuation stays attached to its word.
	var words: [String] {
		split(whereSeparator: \.isWhitespace).map(String.init)
	}
	
	var wordCount: Int {
		words.count
	}
	
	// FIXME: This is just a rough estimate.
	var speakingTime: Duration {
		// 183 words per minute
		.seconds(Double(wordCount) / 3.05)
	}
}
