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

    /// The voices installed here, chosen as the app chooses them.
    private var selection: VoiceSelection<AVSpeechSynthesisVoice> {
        VoiceSelection(installed: AVSpeechSynthesisVoice.speechVoices(), preferredNames: Speakers.preferredVoiceNames, language: Speakers.language)
    }

    /// The available speakers are the preferred voices installed, followed by any standing in for
    /// those that aren't. Created without the cache, as the app creates them.
    @Test func testAvailableSpeakers() {
        let speakers = Speakers()
        let selection = selection
        if !selection.available.isEmpty {
            #expect(speakers.availableSpeakers.map(\.id) == selection.available.map(\.identifier))
        }
        #expect(speakers.missingVoiceNames == selection.missing)
        #expect(speakers.availableSpeakers.isEmpty == false)
    }

    /// The preferred voices are the enhanced Daniel and Arthur.
    @Test func testPreferredVoices() {
        #expect(Speakers.preferredVoiceNames == ["Daniel", "Arthur"])
    }

    /// Each preferred voice has a standard volume, none above full, since a player can't play louder.
    @Test func testVolumesMatchTheVoicesWithoutBoostingAny() {
        for name in Speakers.preferredVoiceNames {
            let volume = Speakers.standardVolumes[name]
            #expect(volume != nil, "\(name) has no volume")
            #expect((volume ?? 0) > 0 && (volume ?? 2) <= 1)
        }
    }

    /// A role without a volume of its own plays at its voice's standard volume.
    @Test func testRolesStartAtTheirVoicesStandardVolumes() {
        let speakers = Speakers.cached()
        for role in speakers.roles.indices {
            #expect(speakers.volume(forRole: role) == Speakers.standardVolume(of: speakers.speaker(forRole: role).voice))
        }
    }

    /// Two roles in the same voice can be played at different volumes.
    @Test func testEachRolesVolumeIsItsOwn() {
        let speakers = Speakers.cached()
        speakers.voices[1] = speakers.voices[0]
        speakers.volumes[speakers.roles[0]] = 0.25
        #expect(speakers.volume(forRole: 0) == 0.25)
        #expect(speakers.volume(forRole: 1) == Speakers.standardVolume(of: speakers.voices[1].voice))
    }

    /// Clearing a role's volume returns it to its voice's standard volume.
    @Test func testClearingARolesVolumeRestoresItsVoicesStandardVolume() {
        let speakers = Speakers.cached()
        speakers.volumes[speakers.roles[0]] = 0.1
        speakers.volumes[speakers.roles[0]] = nil
        #expect(speakers.volume(forRole: 0) == Speakers.standardVolume(of: speakers.speaker(forRole: 0).voice))
    }

    /// A role outside the roles wraps around them for its volume, as for its voice.
    @Test func testVolumesWrap() {
        let speakers = Speakers.cached()
        speakers.volumes[speakers.roles[0]] = 0.3
        #expect(speakers.volume(forRole: 2) == 0.3)
    }

    /// Defaults of their own, so that the tests leave the app's saved volumes alone.
    private func testDefaults() throws -> UserDefaults {
        let name = "SpeakersTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func testSavesAndRestoresTheRolesVolumes() throws {
        let defaults = try testDefaults()
        let speakers = Speakers.cached()
        speakers.volumes["First"] = 0.4
        speakers.saveVolumes(in: defaults)
        #expect(Speakers.savedVolumes(in: defaults) == ["First": 0.4])
    }

    /// Without saved volumes the roles play at their voices' standard volumes, and a saved volume
    /// out of range is brought back within it.
    @Test func testRestoresNoVolumesWhenNoneAreSavedAndClampsThemWhenTheyAre() throws {
        let defaults = try testDefaults()
        #expect(Speakers.savedVolumes(in: defaults).isEmpty)
        defaults.set(["Second": 1.5, "First": -1], forKey: Speakers.volumesDefaultsKey)
        #expect(Speakers.savedVolumes(in: defaults) == ["Second": 1, "First": 0])
    }

    /// The standard score has two roles.
    @Test func testStandardRoles() {
        #expect(speakers.roles == ["First", "Second"])
        #expect(speakers.voices.count == 2)
    }

    /// Each role has its voice from the selection.
    @Test func testRolesHaveTheirVoices() throws {
        let selection = selection
        try #require(!selection.available.isEmpty)
        for role in speakers.roles.indices {
            #expect(speakers.speaker(forRole: role).id == selection.voice(forRole: role)?.identifier)
        }
    }

    /// More roles than preferred voices take them in turn.
    @Test func testVoicesAreGivenToTheRolesInTurn() throws {
        let speakers = Speakers.cached(roles: ["A", "B", "C", "D", "E"])
        let selection = selection
        try #require(!selection.available.isEmpty)
        #expect(speakers.voices.map(\.id) == speakers.roles.indices.map { selection.voice(forRole: $0)?.identifier })
    }

    /// Refreshing keeps the voices when nothing has been installed or removed.
    @Test func testRefreshingWithTheSameVoicesKeepsThem() {
        let speakers = Speakers.cached()
        let before = speakers.voices
        speakers.refresh()
        #expect(speakers.voices == before)
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
