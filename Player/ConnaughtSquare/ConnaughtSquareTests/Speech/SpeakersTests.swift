//
//  SpeakersTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 27/11/2023.
//

import Testing
@testable import ConnaughtSquare
import AVFoundation

extension Speakers {
    /// The installed voices, listed once for all the tests. Each listing queries the system's voice
    /// database, which on the simulator logs a burst of errors every time.
    private static let installedVoices = AVSpeechSynthesisVoice.speechVoices()

    /// Speakers for the roles, from the installed voices listed once for all the tests.
    static func cached(roles: [String] = VoiceNotation.standard.roles) -> Speakers {
        Speakers(roles: roles, installedVoices: installedVoices)
    }
}

/// The installed voices differ between machines, devices and OS versions: one Mac has
/// [Arthur, Daniel, Eddy, Flo, Grandma, Grandpa, Martha, Reed, Rocko, Sandy, Shelley] while
/// another has only [Daniel, Eddy, Flo, Grandma, Grandpa, Reed, Rocko, Sandy, Shelley], and a
/// device may have just [Daniel]. These check how the speakers are selected from whatever is
/// installed rather than naming individual voices.
///
/// Listing the voices blocks on the accessibility framework, so the tests run on the main actor,
/// one at a time. Run in parallel, a dozen of them block every thread in the concurrency pool, and
/// the run hangs.
@MainActor
struct SpeakersTests {
    let speakers = Speakers.cached()

    /// The available speakers are the British English voices, ordered by name. Created without the
    /// cache, as the app creates them.
    @Test func testAvailableSpeakers() {
        let speakers = Speakers()
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
        let speakers = Speakers.cached(roles: ["A", "B", "C", "D", "E"])
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
        let speakers = Speakers.cached(roles: [])
        #expect(speakers.voices.isEmpty)
        #expect(speakers.speaker(forRole: 3) == (try #require(speakers.availableSpeakers.first)))
    }

    /// The standard roles stand at either side, the first on the left.
    @Test func testStandardRolesStandEitherSide() {
        #expect(speakers.pan(forRole: 0) == -Speakers.stereoWidth)
        #expect(speakers.pan(forRole: 1) == Speakers.stereoWidth)
        #expect(Speakers.stereoWidth > 0 && Speakers.stereoWidth <= 1)
    }

    /// More roles are spread evenly from left to right, the outermost at the stereo width.
    @Test func testRolesAreSpreadEvenly() {
        let speakers = Speakers.cached(roles: ["A", "B", "C"])
        #expect(speakers.pan(forRole: 0) == -Speakers.stereoWidth)
        #expect(speakers.pan(forRole: 1) == 0)
        #expect(speakers.pan(forRole: 2) == Speakers.stereoWidth)
    }

    /// A single role, or none, stands in the centre.
    @Test func testASingleRoleStandsInTheCentre() {
        #expect(Speakers.cached(roles: ["Only"]).pan(forRole: 0) == 0)
        #expect(Speakers.cached(roles: []).pan(forRole: 3) == 0)
    }

    /// A role outside the roles stands where the role it wraps around to stands.
    @Test func testPansWrap() {
        #expect(speakers.pan(forRole: 2) == speakers.pan(forRole: 0))
        #expect(speakers.pan(forRole: -1) == speakers.pan(forRole: 1))
    }

    /// Choosing a voice for a role changes who speaks for it.
    @Test func testChoosingAVoice() throws {
        let last = try #require(speakers.availableSpeakers.last)
        speakers.voices[0] = last
        #expect(speakers.speaker(forRole: 0) == last)
    }
}
