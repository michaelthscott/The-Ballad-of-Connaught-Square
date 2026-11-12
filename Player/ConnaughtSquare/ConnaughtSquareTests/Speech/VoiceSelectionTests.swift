//
//  VoiceSelectionTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 11/11/2026.
//

import Testing
import AVFoundation
@testable import ConnaughtSquare

/// A voice that needn't be installed, for choosing among.
private struct StubVoice: VoiceDescription {
    let name: String
    var language = "en-GB"
    var quality: AVSpeechSynthesisVoiceQuality = .default
}

private let compactDaniel = StubVoice(name: "Daniel")
private let enhancedDaniel = StubVoice(name: "Daniel (Enhanced)", quality: .enhanced)
private let premiumDaniel = StubVoice(name: "Daniel (Premium)", quality: .premium)
private let enhancedArthur = StubVoice(name: "Arthur (Enhanced)", quality: .enhanced)
private let eddy = StubVoice(name: "Eddy")
private let flo = StubVoice(name: "Flo")
private let americanArthur = StubVoice(name: "Arthur (Enhanced)", language: "en-US", quality: .enhanced)

struct VoiceSelectionTests {
    private func selection(_ installed: [StubVoice]) -> VoiceSelection<StubVoice> {
        VoiceSelection(installed: installed, preferredNames: ["Daniel", "Arthur"], language: "en-GB")
    }

    @Test func testOffersOnlyThePreferredVoicesWhenTheyreInstalled() {
        let selection = selection([eddy, compactDaniel, enhancedArthur, enhancedDaniel, flo])
        #expect(selection.available == [enhancedDaniel, enhancedArthur])
        #expect(selection.missing.isEmpty)
    }

    @Test func testGivesTheRolesThePreferredVoicesInTurn() {
        let selection = selection([enhancedArthur, enhancedDaniel])
        #expect(selection.voice(forRole: 0) == enhancedDaniel)
        #expect(selection.voice(forRole: 1) == enhancedArthur)
        #expect(selection.voice(forRole: 2) == enhancedDaniel)
        #expect(selection.voice(forRole: -1) == enhancedArthur)
    }

    @Test func testPrefersThePremiumDownload() {
        let selection = selection([enhancedDaniel, premiumDaniel, enhancedArthur])
        #expect(selection.available == [premiumDaniel, enhancedArthur])
        #expect(selection.voice(forRole: 0) == premiumDaniel)
    }

    @Test func testListsThePreferredVoicesThatArentInstalled() {
        #expect(selection([enhancedDaniel, eddy]).missing == ["Arthur"])
        #expect(selection([compactDaniel, eddy]).missing == ["Daniel", "Arthur"])
    }

    @Test func testDoesntCountTheCompactDownloadAsPreferred() {
        let selection = selection([compactDaniel, enhancedArthur])
        #expect(selection.missing == ["Daniel"])
        #expect(!selection.isPreferred(compactDaniel))
        #expect(selection.isPreferred(enhancedArthur))
    }

    @Test func testOffersOtherVoicesWhileOneIsMissingTheSameVoiceFirst() {
        let selection = selection([eddy, flo, compactDaniel, enhancedArthur])
        #expect(selection.available == [enhancedArthur, compactDaniel, eddy, flo])
    }

    @Test func testStandsTheSameVoicesSmallerDownloadInForIt() {
        let selection = selection([eddy, compactDaniel, enhancedArthur])
        #expect(selection.voice(forRole: 0) == compactDaniel)
        #expect(selection.voice(forRole: 1) == enhancedArthur)
    }

    @Test func testStandsOtherVoicesInWhenTheSameVoiceIsntInstalled() {
        let selection = selection([flo, eddy, enhancedDaniel])
        #expect(selection.voice(forRole: 0) == enhancedDaniel)
        // Arthur isn't installed at all, so the second role takes the second voice available.
        #expect(selection.voice(forRole: 1) == eddy)
    }

    @Test func testIgnoresVoicesInOtherLanguages() {
        let selection = selection([enhancedDaniel, americanArthur])
        #expect(selection.missing == ["Arthur"])
        #expect(!selection.available.contains(americanArthur))
    }

    @Test func testHasNoVoiceWhenNoneIsInstalled() {
        let selection = selection([americanArthur])
        #expect(selection.available.isEmpty)
        #expect(selection.voice(forRole: 0) == nil)
    }

    @Test func testTakesTheNameWithoutItsQuality() {
        #expect(VoiceSelection<StubVoice>.baseName(of: "Daniel (Enhanced)") == "Daniel")
        #expect(VoiceSelection<StubVoice>.baseName(of: "Daniel") == "Daniel")
    }
}
