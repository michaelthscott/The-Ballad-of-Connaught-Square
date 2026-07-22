//
//  SpeakersTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 27/11/2023.
//

import Testing
@testable import ConnaughtSquare
import AVFoundation
#if os(iOS)
import UIKit
#endif

final class SpeakersTests {
    var speakers: Speakers!
    
    init() throws {
        speakers = Speakers()
    }

    deinit {
        speakers = nil
    }

	// macOS: [Arthur, Daniel, Eddy, Flo, Grandma, Grandpa, Martha, Reed, Rocko, Sandy, Shelley]
	// iOS: [Daniel]
	
	// iPhone: [Arthur, Daniel, Daniel (Enhanced), Eddy, Flo, Grandma, Grandpa, Martha, Reed, Rocko, Sandy, Shelley]
	// #FactoryInstall Unable to query results, error: 5
	// Unable to list voice folder x 5
	// AggregateDictionary is deprecated and has been removed. Please migrate to Core Analytics.
	
    @Test func testFirstSpeaker() throws {
#if os(macOS)
        #expect(speakers.firstSpeaker.name == "Arthur")
#else
		if UIDevice.current.name == "iPhone" {
            #expect(speakers.firstSpeaker.name == "Arthur")
		} else {
            #expect(speakers.firstSpeaker.name == "Daniel")
		}
#endif
    }
	
    @Test func testSecondSpeaker() throws {
        #expect(speakers.secondSpeaker.name == "Daniel")
    }

}
