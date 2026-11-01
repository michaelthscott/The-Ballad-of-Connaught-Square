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

    /// The standard score has two roles.
    @Test func testStandardRoles() {
        #expect(speakers.roles == ["First", "Second"])
        #expect(speakers.voices.count == 2)
    }

    @Test func testFirstRoleHasTheFirstAvailableVoice() throws {
        let first = try #require(speakers.availableSpeakers.first)
        #expect(speakers.speaker(forRole: 0) == first)
    }

    /// The second role has the next available voice, or the only voice when there is just one.
    @Test func testSecondRoleHasTheNextAvailableVoice() throws {
        let available = speakers.availableSpeakers
        let expected = try #require(available.count > 1 ? available[1] : available.first)
        #expect(speakers.speaker(forRole: 1) == expected)
    }

    /// The available voices are given to the roles in turn, and shared when there are more roles than voices.
    @Test func testVoicesAreGivenToTheRolesInTurn() {
        let speakers = Speakers(roles: ["A", "B", "C", "D", "E"])
        let available = speakers.availableSpeakers
        #expect(speakers.voices == speakers.roles.indices.map { available[$0 % available.count] })
    }

    /// A role outside the roles wraps around them.
    @Test func testRolesWrap() {
        #expect(speakers.speaker(forRole: 2) == speakers.speaker(forRole: 0))
        #expect(speakers.speaker(forRole: -1) == speakers.speaker(forRole: 1))
    }

    /// Without any roles, the first available voice speaks.
    @Test func testNoRoles() throws {
        let speakers = Speakers(roles: [])
        #expect(speakers.voices.isEmpty)
        #expect(speakers.speaker(forRole: 3) == (try #require(speakers.availableSpeakers.first)))
    }

    /// Choosing a voice for a role changes who speaks for it.
    @Test func testChoosingAVoice() throws {
        let last = try #require(speakers.availableSpeakers.last)
        speakers.voices[0] = last
        #expect(speakers.speaker(forRole: 0) == last)
    }
}
