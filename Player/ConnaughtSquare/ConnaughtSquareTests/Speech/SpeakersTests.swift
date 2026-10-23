//
//  SpeakersTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 27/11/2023.
//

import Testing
@testable import ConnaughtSquare
import AVFoundation

/// The installed voices differ between machines, devices and OS versions: one Mac has
/// [Arthur, Daniel, Eddy, Flo, Grandma, Grandpa, Martha, Reed, Rocko, Sandy, Shelley] while
/// another has only [Daniel, Eddy, Flo, Grandma, Grandpa, Reed, Rocko, Sandy, Shelley], and a
/// device may have just [Daniel]. These check how the speakers are selected from whatever is
/// installed rather than naming individual voices.
struct SpeakersTests {
    let speakers = Speakers()

    /// The available speakers are the British English voices, ordered by name.
    @Test func testAvailableSpeakers() {
        let expected = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == Speakers.language }
            .map { $0.name }
            .sorted()
        #expect(speakers.availableSpeakers.map { $0.name } == expected)
        #expect(speakers.availableSpeakers.isEmpty == false)
    }

    @Test func testFirstSpeakerIsTheFirstAvailableVoice() throws {
        let first = try #require(speakers.availableSpeakers.first)
        #expect(speakers.firstSpeaker == first)
    }

    /// The second speaker is the next available voice, or the only voice when there is just one.
    @Test func testSecondSpeakerIsTheNextAvailableVoice() throws {
        let available = speakers.availableSpeakers
        let expected = try #require(available.count > 1 ? available[1] : available.first)
        #expect(speakers.secondSpeaker == expected)
    }

    @Test func testSelectedSpeakers() {
        #expect(speakers.selectedSpeakers == [speakers.firstSpeaker, speakers.secondSpeaker])
    }

    /// The speakers take turns, starting with the second speaker.
    @Test func testTakeTurnAlternates() {
        #expect(speakers.takeTurn() == speakers.secondSpeaker)
        #expect(speakers.takeTurn() == speakers.firstSpeaker)
        #expect(speakers.takeTurn() == speakers.secondSpeaker)
        #expect(speakers.takeTurn() == speakers.firstSpeaker)
    }

    /// Resetting the turns starts them again with the second speaker.
    @Test func testResetTurns() {
        _ = speakers.takeTurn()
        speakers.resetTurns()
        #expect(speakers.takeTurn() == speakers.secondSpeaker)
        #expect(speakers.takeTurn() == speakers.firstSpeaker)
    }

    @Test func testMaxSelectedSpeakersMatchesTheSelection() {
        #expect(speakers.selectedSpeakers.count == Speakers.maxSelectedSpeakers)
    }
}
