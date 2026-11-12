//
//  DeclamationTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 11/11/2026.
//

import Testing
import Foundation
import AVFoundation
@testable import ConnaughtSquare

struct DeclamationTests {
    private func declamation(_ string: String, _ position: PartPosition = .lineEnd) -> Declamation {
        Declamation(string: string, position: position)
    }

    @Test func testSplitsTheWordsKeepingTheirPunctuation() {
        #expect(declamation("Yeah will be yeah, so…").words.map(\.text) == ["Yeah", "will", "be", "yeah,", "so…"])
    }

    @Test func testReadsTheMarkEndingEachWord() {
        let marks = declamation("Well, are you… there? Yes! No.").words.map(\.mark)
        #expect(marks == [.comma, .none, .ellipsis, .question, .exclamation, .fullStop])
    }

    @Test func testStressesContentWordsButNotFunctionWords() {
        let words = declamation("Have you got the Christmas tree.").words
        #expect(words.map(\.isStressed) == [false, false, true, false, true, true])
    }

    @Test func testKeepsTheArticleBeforeAnEllipsisUnstressed() throws {
        let last = try #require(declamation("Have you got a…").words.last)
        #expect(last.text == "a…")
        #expect(!last.isStressed)
    }

    @Test func testLeavesFillersUnstressed() {
        #expect(!Declamation.isStressed("ah…", in: .shared))
        #expect(!Declamation.isStressed("Mmm.", in: .shared))
    }

    @Test func testStressesWordsTheLexiconDoesNotKnow() {
        #expect(Declamation.isStressed("Marylebone?", in: .shared))
    }

    @Test func testSlowsTheStressedWords() {
        let words = declamation("Can do that.").words
        let style = DeclamationStyle.standard
        #expect(words[0].rate == style.baseRate)
        #expect(words[2].rate == style.baseRate * style.stressRate)
    }

    @Test func testRisesToTheFirstStress() {
        let words = declamation("Have you got the bus.").words
        #expect(words[0].pitch < words[1].pitch)
        #expect(words[1].pitch < words[2].pitch)
    }

    @Test func testFallsAtTheEndOfALineWithAFullStop() throws {
        let words = declamation("Might see you in a minute.").words
        let last = try #require(words.last)
        #expect(last.pitch < words[words.count - 2].pitch)
    }

    @Test func testHoldsAtACaesuraWithAFullStop() throws {
        let atLineEnd = declamation("Might see you in a minute.", .lineEnd).words.last?.pitch
        let atCaesura = declamation("Might see you in a minute.", .caesura).words.last?.pitch
        let fall = try #require(atCaesura) - (try #require(atLineEnd))
        #expect(abs(fall - DeclamationStyle.standard.finalFall) < 1e-9)
    }

    @Test func testDoesNotFallAtATrailingEllipsis() throws {
        let words = declamation("Might see you in a…").words
        let last = try #require(words.last)
        #expect(last.pitch >= words[words.count - 2].pitch - DeclamationStyle.standard.stressBoost)
        let stopped = try #require(declamation("Might see you in a.").words.last)
        #expect(last.pitch > stopped.pitch)
    }

    @Test func testRisesAtAQuestion() throws {
        let question = try #require(declamation("Are you back here later?").words.last)
        let statement = try #require(declamation("Are you back here later.").words.last)
        #expect(question.pitch > statement.pitch)
    }

    @Test func testPutsTheQuestionOnTheLastStressedWord() throws {
        let words = declamation("Are you back here later?").words
        let last = try #require(words.last)
        for word in words.dropLast() {
            #expect(word.pitch < last.pitch, "\(word.text) shouldn't be as high as the question's end")
        }
        // The earlier stressed words aren't lifted above one another, so none sounds like the question.
        #expect(words[2].pitch == words[3].pitch)
    }

    @Test func testRisesFromTheLastStressedWordToTheEndOfAQuestion() {
        let words = declamation("Is Marylebone open to us?").words
        // "open" is the last stressed word; "to" and "us" carry the rise on to the end.
        #expect(words[3].pitch < words[4].pitch)
        #expect(words[2].pitch < words[4].pitch)
    }

    @Test func testFallsAtTheEndOfAQuestionThatOpensWithAQuestionWord() throws {
        let question = try #require(declamation("Where are you going later?").words.last)
        let statement = try #require(declamation("Where are you going later.").words.last)
        #expect(question.pitch == statement.pitch)
    }

    @Test func testTellsYesNoQuestionsFromQuestionsThatAskForInformation() {
        #expect(Declamation.isYesNoQuestion(declamation("Are you back here later?").words))
        #expect(!Declamation.isYesNoQuestion(declamation("How are you?").words))
        #expect(!Declamation.isYesNoQuestion(declamation("Are you back here later.").words))
    }

    @Test func testHoldsThePitchAcrossAHesitation() {
        let words = declamation("Had intended doing ah… Christmas on the beat.").words
        let style = DeclamationStyle.standard
        // "ah…" is unstressed and "Christmas" stressed, so the line holds where the stress boost doesn't.
        #expect(abs(words[4].pitch - style.stressBoost - words[3].pitch) < 1e-9)
    }

    @Test func testPausesLongestAfterATrailingEllipsisThenAHesitationThenAComma() {
        let style = DeclamationStyle.standard
        let trailing = declamation("Yeah will be yeah, so…").words
        let hesitating = declamation("Had intended doing ah… Christmas on the beat.").words
        #expect(trailing.last?.pauseAfter == style.trailingEllipsisPause)
        #expect(hesitating[3].pauseAfter == style.hesitationPause)
        #expect(trailing[3].pauseAfter == style.commaPause)
        #expect(style.trailingEllipsisPause > style.hesitationPause)
        #expect(style.hesitationPause > style.commaPause)
    }

    @Test func testPausesAfterThePartByItsPosition() {
        let style = DeclamationStyle.standard
        #expect(declamation("Can do that.", .lineEnd).words.last?.pauseAfter == style.lineEndPause)
        #expect(declamation("Can do that.", .caesura).words.last?.pauseAfter == style.caesuraPause)
        #expect(declamation("Can do that.").words.first?.pauseAfter == .zero)
    }

    @Test func testTakesThePositionFromTheLine() {
        let first = Part(string: "Can do that.")
        let second = Part(string: "No.")
        let line = Line(parts: [first, second], tags: [])
        #expect(Declamation(part: first, in: line).position == .caesura)
        #expect(Declamation(part: second, in: line).position == .lineEnd)
    }

    @Test func testGivesEachPronunciationToTheWordItCovers() {
        let pronunciation = CorrectPronunciation(ipa: "ˈmɑːlɪbən", location: 3, length: 10)
        let words = Declamation(string: "Is Marylebone open?", pronunciations: [pronunciation], position: .lineEnd).words
        #expect(words.map(\.ipa) == [nil, "ˈmɑːlɪbən", nil])
    }

    @Test func testIsEmptyForAnEmptyPart() {
        #expect(declamation("").words.isEmpty)
    }

    @Test func testTakesTheBaselineFromTheMostFrequentNote() {
        let viola = Event(instrument: Instrument(name: .viola),
                          notes: Cycle(elements: [Note(value: .a2, duration: .crotchet), Note(value: .c3, duration: .crotchet)]),
                          stretches: [])
        let cello = Event(instrument: Instrument(name: .cello),
                          notes: Cycle(elements: [Note(value: .c3, duration: .minim), Note(value: .e3, duration: .minim)]),
                          stretches: [])
        #expect(Declamation.baseline(for: [viola, cello]) == .c3)
        #expect(Declamation.baseline(for: []) == nil)
    }

    @Test func testTakesTheLowestNoteWhenNotesTie() {
        let event = Event(instrument: Instrument(name: .viola),
                          notes: Cycle(elements: [Note(value: .e3, duration: .crotchet), Note(value: .a2, duration: .crotchet)]),
                          stretches: [])
        #expect(Declamation.baseline(for: [event]) == .a2)
    }

    @Test func testMeasuresTheBaselineFromTheStylesReferenceNote() {
        var style = DeclamationStyle()
        style.reference = .c3
        style.baselineWeight = 1
        let declamation = Declamation(string: "Can do that.", position: .lineEnd, baseline: .e3, style: style)
        #expect(declamation.baselineOffset == 4)
        style.baselineWeight = 0.5
        #expect(Declamation(string: "Can do that.", position: .lineEnd, baseline: .e3, style: style).baselineOffset == 2)
        #expect(self.declamation("Can do that.").baselineOffset == 0)
    }

    @Test func testMovesEveryWordByTheBaseline() {
        var declamation = declamation("Can do that.")
        let unmoved = declamation.pitches
        declamation.baseline = .a2
        let offset = declamation.baselineOffset
        #expect(offset != 0)
        #expect(zip(declamation.pitches, unmoved).allSatisfy { abs($0 - $1 - offset) < 1e-9 })
    }

    @Test func testCarriesTheStyleItWasShapedWith() {
        var style = DeclamationStyle()
        style.baseRate = 0.5
        style.reference = .e3
        #expect(Declamation(string: "Can do that.", position: .lineEnd, style: style).style == style)
    }

    @Test func testExpectsSlowerRatesToTakeLongerAndCountsThePauses() {
        var slow = DeclamationStyle()
        slow.baseRate = 0.5
        var fast = DeclamationStyle()
        fast.baseRate = 1
        let string = "Had intended doing ah… Christmas on the beat."
        let slowly = Declamation(string: string, position: .lineEnd, style: slow)
        let quickly = Declamation(string: string, position: .lineEnd, style: fast)
        #expect(slowly.expectedDuration > quickly.expectedDuration)
        // At the default rate, the words take their plain speaking time, and the pauses come on top.
        let pauses = quickly.words.reduce(Duration.zero) { $0 + $1.pauseAfter }
        // Scaling a duration rounds it at the attosecond, so they're compared to the microsecond.
        let difference = quickly.expectedDuration - (string.speakingTime + pauses)
        #expect(abs(difference.components.seconds) == 0 && abs(difference.components.attoseconds) < 1_000_000_000_000)
    }

    @Test func testSlowsLessThanInProportion() {
        #expect(Declamation.lengthening(atRate: 1) == 1)
        let atSeventy = Declamation.lengthening(atRate: 0.7)
        #expect(atSeventy > 1.1 && atSeventy < 1.25)
    }

    /// Defaults of their own, so that the tests leave the app's saved style alone.
    private func testDefaults() throws -> UserDefaults {
        let name = "DeclamationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func testSavesAndRestoresTheStyle() throws {
        let defaults = try testDefaults()
        var style = DeclamationStyle()
        style.baseRate = 0.55
        style.commaPause = .milliseconds(325)
        style.reference = .e3
        style.save(in: defaults)
        #expect(DeclamationStyle.saved(in: defaults) == style)
    }

    @Test func testRestoresTheStandardStyleWhenNoneIsSaved() throws {
        #expect(DeclamationStyle.saved(in: try testDefaults()) == .standard)
    }

    @Test func testRestoresTheStandardStyleWhenTheSavedOneCantBeRead() throws {
        let defaults = try testDefaults()
        defaults.set(Data("not a style".utf8), forKey: DeclamationStyle.defaultsKey)
        #expect(DeclamationStyle.saved(in: defaults) == .standard)
    }

    /// A style saved before a tunable was added keeps its other values, taking the new one's standard value.
    @Test func testRestoresTheStandardValueOfAnyTunableNotSaved() throws {
        let defaults = try testDefaults()
        defaults.set(Data(#"{"baseRate": 0.5}"#.utf8), forKey: DeclamationStyle.defaultsKey)
        var expected = DeclamationStyle.standard
        expected.baseRate = 0.5
        #expect(DeclamationStyle.saved(in: defaults) == expected)
    }

    @Test func testSpeaksPlainlyWithEachPronunciationOnItsWord() {
        let pronunciation = CorrectPronunciation(ipa: "ˈmɑːlɪbən", location: 3, length: 10)
        let string = Declamation(string: "Is Marylebone open?", pronunciations: [pronunciation], position: .lineEnd).attributedString
        #expect(string.string == "Is Marylebone open?")
        let key = NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute)
        var ranges: [NSRange] = []
        string.enumerateAttribute(key, in: NSRange(location: 0, length: string.length)) { value, range, _ in
            if value as? String == "ˈmɑːlɪbən" { ranges.append(range) }
        }
        #expect(ranges == [NSRange(location: 3, length: 10)])
    }
}
