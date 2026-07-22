//
//  StringExtensions.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 20/01/2024.
//

import Foundation

extension String {
	var words: [String] {
		components(separatedBy: .whitespaces)
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
