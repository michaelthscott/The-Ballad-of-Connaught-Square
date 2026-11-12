//
//  SSMLRendererTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 11/11/2026.
//

import Testing
import AVFoundation
@testable import ConnaughtSquare

struct SSMLRendererTests {
    @Test(arguments: [
        "Had intended doing ah… Christmas on the beat.",
        "We're going to Oxford Street.",
        "Yeah will be yeah, so…",
        "Tom & Jerry <live>",
    ])
    func testWritesSSMLTheUtteranceAccepts(_ string: String) {
        let ssml = SSMLRenderer.ssml(for: Declamation(string: string, position: .lineEnd, baseline: .a2))
        #expect(AVSpeechUtterance(ssmlRepresentation: ssml) != nil)
    }

    @Test func testWritesEachWordWithItsPitchAndRate() {
        let ssml = SSMLRenderer.ssml(for: Declamation(string: "Can do that.", position: .caesura))
        // The part's rate is written once around it; only the stressed word has a rate of its own.
        #expect(ssml.hasPrefix("<speak><prosody rate=\"70%\"><prosody pitch=\"+0.0%\">Can</prosody> "))
        // The stressed word's rate replaces the part's, so it's written in full: 70% slowed to nine tenths.
        #expect(ssml.hasSuffix(" rate=\"63%\">that.</prosody><break time=\"250ms\"/></prosody></speak>"))
    }

    @Test func testBreaksAtEachPause() {
        let ssml = SSMLRenderer.ssml(for: Declamation(string: "Had intended doing ah… Christmas on the beat.", position: .lineEnd))
        #expect(ssml.contains(">ah…</prosody><break time=\"450ms\"/>"))
        #expect(ssml.hasSuffix("<break time=\"500ms\"/></prosody></speak>"))
    }

    @Test func testWritesCorrectPronunciationsAsPhonemes() {
        let pronunciation = CorrectPronunciation(ipa: "ˈmɑːlɪbən", location: 3, length: 10)
        let declamation = Declamation(string: "Is Marylebone open?", pronunciations: [pronunciation], position: .lineEnd)
        #expect(SSMLRenderer.ssml(for: declamation).contains("<phoneme alphabet=\"ipa\" ph=\"ˈmɑːlɪbən\">Marylebone</phoneme>"))
    }

    @Test func testBringsTheVoiceToTheSamePace() {
        let ssml = SSMLRenderer.ssml(for: Declamation(string: "Can do that.", position: .caesura), pace: 0.8)
        // The base rate of 70%, slowed to four fifths.
        #expect(ssml.hasPrefix("<speak><prosody rate=\"56%\"><prosody pitch=\"+0.0%\">Can</prosody> "))
    }

    @Test func testEscapesTheCharactersXMLReserves() {
        #expect(SSMLRenderer.escaped("We're <Tom & \"Jerry\">") == "We&apos;re &lt;Tom &amp; &quot;Jerry&quot;&gt;")
    }

    @Test func testWritesSemitonesAsAChangeInFrequency() {
        #expect(SSMLRenderer.percentage(semitones: 0) == "+0.0%")
        #expect(SSMLRenderer.percentage(semitones: 12) == "+100.0%")
        #expect(SSMLRenderer.percentage(semitones: -12) == "-50.0%")
    }

    @Test func testMovesThePitchByTheWeightedBaseline() {
        var style = DeclamationStyle()
        style.reference = .c3
        style.baselineWeight = 0.5
        let declamation = Declamation(string: "Can do that.", position: .caesura, baseline: .a2, style: style)
        // A2 is three semitones below C3, and half of that is followed.
        #expect(SSMLRenderer.ssml(for: declamation).hasPrefix("<speak><prosody rate=\"70%\"><prosody pitch=\"\(SSMLRenderer.percentage(semitones: -1.5))\""))
    }
}
