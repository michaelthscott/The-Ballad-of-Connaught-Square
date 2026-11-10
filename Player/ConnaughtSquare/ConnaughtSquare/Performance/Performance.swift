//
//  Performance.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 17/01/2024.
//

import Foundation
import os
import Synchronization

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ConnaughtSquare", category: "Performance")

/// A performance of the ballad with musical accompaniment.
///
/// The performance runs as a single cancellable task on the main actor, performing one cue for each
/// part as the score notates it. Any intermission plays in full first. Then the part is recited on
/// the main actor once the cue reaches its recitation, while each instrument plays its stretches in
/// a child task off it, and the cue finishes when they're all done.
///
/// Pausing closes the sound bank's pause gate, which halts the accompaniment at its next note and
/// the recitation at its next part, and pauses the voice and the audio engine in place.
@MainActor @Observable final class Performance {
    enum PlaybackState {
        case stopped
        case playing
        case paused
    }

    var spokenPartCount: Int = 0
    /// Whether the ballad's title has been shown, which happens as the performance starts, before the introduction.
    private(set) var isTitleAnnounced = false
    /// How long the last performance's title stays cleared when the ballad is performed again.
    static let titleClearing: Duration = .seconds(1)
    /// The number of cantos whose titles have been shown, which happens as each canto's first
    /// stanza starts, before it's recited.
    private(set) var announcedCantoCount: Int = 0
    let ballad: Ballad
    let speakers: Speakers
    let score: Score
    let arranger: Arranger
    private(set) var state: PlaybackState = .stopped

    private let speech: any SpeechSynthesizing
    private let soundBank: SoundBank
    private var performanceTask: Task<Void, Never>?
    /// The most recent change to the audio engine. Each change waits for the previous one, so the
    /// engine is paused, resumed and stopped in the order they were requested.
    private var engineControlTask: Task<Void, Never>?

    /// Creates a performance of the ballad as the score notates it.
    /// - Parameters:
    ///   - score: The score.
    ///   - ballad: The ballad.
    ///   - speakers: The voices for the roles. By default, a voice is chosen for each of the standard roles.
    ///   - soundBank: The sound bank to play on.
    ///   - speech: What recites the parts. By default, a speech synthesizer.
    init(score: Score = .bundled,
         ballad: Ballad = Ballad(),
         speakers: Speakers? = nil,
         soundBank: SoundBank = .shared,
         speech: (any SpeechSynthesizing)? = nil) {
        self.score = score
        arranger = Arranger(score: score)
        self.ballad = ballad
        self.speakers = speakers ?? Speakers()
        self.soundBank = soundBank
        self.speech = speech ?? SpeechSynthesizer()
    }

    /// Starts performing the ballad from the beginning, or resumes a paused performance.
    /// Does nothing if the performance is already playing.
    func play() {
        switch state {
        case .stopped:
            let clearsTitle = isTitleAnnounced
            ballad.isRecited = false
            spokenPartCount = 0
            isTitleAnnounced = false
            announcedCantoCount = 0
            soundBank.pauseGate.resume()
            state = .playing
            performanceTask = Task { [weak self] in
                await self?.run(clearingTitle: clearsTitle)
            }
        case .paused:
            resume()
        case .playing:
            break
        }
    }

    /// Pauses the performance in place. Does nothing unless the performance is playing.
    func pause() {
        guard state == .playing else { return }
        soundBank.pauseGate.pause()
        speech.pause()
        controlEngine { await $0.pauseEngine() }
        state = .paused
    }

    /// Resumes a paused performance from where it was paused. Does nothing unless the performance is paused.
    func resume() {
        guard state == .paused else { return }
        controlEngine { soundBank in
            do {
                try await soundBank.resumeEngine()
            } catch {
                logger.error("Couldn't resume the audio engine: \(String(describing: error))")
            }
        }
        speech.resume()
        soundBank.pauseGate.resume()
        state = .playing
    }

    /// Stops the performance, silencing the voices and the accompaniment.
    func stop() {
        performanceTask?.cancel()
        performanceTask = nil
        // Release anything waiting at the gate so that it can see it has been cancelled.
        soundBank.pauseGate.resume()
        speech.stop()
        controlEngine { await $0.stopEngine() }
        state = .stopped
    }

    /// Changes the audio engine after any earlier change has been made.
    private func controlEngine(_ change: @escaping @Sendable (SoundBank) async -> Void) {
        let previous = engineControlTask
        let soundBank = soundBank
        engineControlTask = Task {
            await previous?.value
            await change(soundBank)
        }
    }

    /// Performs the ballad from the beginning.
    /// - Parameter clearingTitle: Whether the last performance's title was showing, so it's left
    ///   cleared for a moment, while the performance gets ready, to be seen to go before it appears again.
    private func run(clearingTitle: Bool = false) async {
        let soundBank = soundBank
        async let titleCleared: Void = {
            if clearingTitle {
                try? await soundBank.pauseGate.sleep(for: Self.titleClearing)
            }
        }()
        // The accompaniment starts the engine itself, outside the queue of engine changes, so let
        // the last performance's stop take effect first; otherwise it could stop this one's engine.
        await engineControlTask?.value
        // Ready the voices while the introduction plays, so that none starts its first part stuttering.
        speech.warmUp(speakers.voices.map(\.voice))
        // Load every instrument before the introduction, so that none loads its preset while others
        // play. It's queued with the engine changes, so a stop meanwhile takes effect after it.
        let instruments = score.instruments
        controlEngine { soundBank in
            do {
                try await soundBank.warmUp(instruments)
            } catch {
                logger.error("Couldn't warm up the instruments: \(String(describing: error))")
            }
        }
        await engineControlTask?.value
        await titleCleared
        var events = EventsSequence(performance: self)
        // Where each instrument's melody stopped in the last part, for the next to carry on.
        var melodies: [InstrumentName: Cycle<Note>] = [:]
        while !Task.isCancelled, let cue = events.next(continuing: melodies) {
            await soundBank.pauseGate.wait()
            guard !Task.isCancelled else { break }
            melodies = await perform(cue)
        }
        // A cancelled performance was stopped, and `stop()` has already tidied up — possibly
        // before a new performance started, which this mustn't disturb.
        guard !Task.isCancelled else { return }
        performanceTask = nil
        controlEngine { await $0.stopEngine() }
        state = .stopped
    }

    /// Performs one cue, returning when the recitation and every instrument have finished.
    /// - Returns: Where each instrument's melody stopped, not counting the intermission's.
    private func perform(_ cue: Cue) async -> [InstrumentName: Cycle<Note>] {
        logger.debug("\(cue.description)")
        let soundBank = soundBank
        // Show the ballad's title as the performance starts, and rest after it as the score says
        // before the introduction. Time paused doesn't count towards a rest.
        if cue.beginsBallad {
            isTitleAnnounced = true
            if cue.balladTitleRest > .zero {
                try? await soundBank.pauseGate.sleep(for: cue.balladTitleRest)
                guard !Task.isCancelled else { return [:] }
            }
        }
        await Self.playIntermission(cue.intermission, lasting: cue.intermissionLength, on: soundBank)
        guard !Task.isCancelled else { return [:] }
        // Show the canto's title before its first stanza is recited, and rest after it as the
        // score says before the stanza's music comes in.
        if let cantoIndex = cue.cantoIndex {
            announcedCantoCount = max(announcedCantoCount, cantoIndex + 1)
            if cue.cantoTitleRest > .zero {
                try? await soundBank.pauseGate.sleep(for: cue.cantoTitleRest)
                guard !Task.isCancelled else { return [:] }
            }
        }
        // The recitation is a task of its own, so that instruments playing until it finishes can wait
        // for it. It runs on the main actor, as this does. Time paused doesn't count towards its start.
        let part = cue.part
        let speaker = cue.speaker
        let pan = cue.pan
        let recitationStart = cue.recitationStart
        let recitation = Task {
            try? await soundBank.pauseGate.sleep(for: recitationStart)
            await soundBank.pauseGate.wait()
            guard !Task.isCancelled else { return }
            await self.recite(part, as: speaker, at: pan)
        }
        // The events are `Sendable`, so they play off the main actor while the part — which isn't —
        // is recited on it. Take them out of the cue first, so the child task doesn't capture its part.
        let events = cue.events
        async let melodies = Self.play(events, on: soundBank, alongside: recitation)
        await withTaskCancellationHandler {
            await recitation.value
        } onCancel: {
            recitation.cancel()
        }
        return await melodies
    }

    /// Recites the part in the speaker's voice, from where the speaker stands in stereo.
    ///
    /// The part is marked as recited before speech begins so that the text appears as it is spoken.
    private func recite(_ part: Part, as speaker: Speaker, at pan: Float) async {
        part.isRecited = true
        spokenPartCount += 1
        await speech.speak(part.nsAttributedString, in: speaker.voice, pan: pan)
    }

    /// Plays an intermission's events together, returning once they've finished and its length has
    /// passed. Time paused doesn't count towards it. `nonisolated` so it runs off the main actor.
    nonisolated static func playIntermission(_ events: [Event], lasting length: Duration, on soundBank: SoundBank) async {
        guard !events.isEmpty || length > .zero else { return }
        // Nothing is recited in an intermission, so nothing in it waits for a recitation.
        let noRecitation = Task<Void, Never> {}
        async let rest: Void = { try? await soundBank.pauseGate.sleep(for: length) }()
        _ = await play(events, on: soundBank, alongside: noRecitation)
        await rest
    }

    /// Plays the events together, from the start of the cue, returning once they've all finished.
    /// `nonisolated` so it runs off the main actor.
    /// - Parameters:
    ///   - events: The events to play.
    ///   - soundBank: The sound bank to play on.
    ///   - recitation: The recitation that times counted from the end of the recitation wait for.
    /// - Returns: Where each instrument's melody stopped, so that the next part can carry it on.
    nonisolated static func play(_ events: [Event], on soundBank: SoundBank, alongside recitation: Task<Void, Never>) async -> [InstrumentName: Cycle<Note>] {
        let recited = Flag()
        return await withTaskGroup(of: (InstrumentName, Cycle<Note>)?.self) { group in
            group.addTask {
                await recitation.value
                recited.set()
                return nil
            }
            for event in events {
                group.addTask {
                    (event.instrument.name, await play(event, on: soundBank, alongside: recitation, recited: recited))
                }
            }
            var melodies: [InstrumentName: Cycle<Note>] = [:]
            for await case let (instrument, melody)? in group {
                melodies[instrument] = melody
            }
            return melodies
        }
    }

    /// Plays the event's stretches in turn, carrying its melody on from one to the next.
    ///
    /// Each note is played in full, so a stretch can run past its end by part of a note; the instrument
    /// makes that up by starting the next stretch, or waiting out the gap before it, that much later.
    /// - Returns: The melody, moved on past the notes played.
    private nonisolated static func play(_ event: Event, on soundBank: SoundBank, alongside recitation: Task<Void, Never>, recited: Flag) async -> Cycle<Note> {
        var notes = event.notes
        let instrument = event.instrument.name
        // Where the instrument has reached in the cue, and how far its last note ran past it.
        var position = Moment.seconds(0)
        var overrun = Duration.zero
        do {
            for stretch in event.stretches {
                // Wait out any gap since the last stretch.
                switch (position, stretch.start) {
                case (.seconds(let from), .seconds(let to)), (.afterRecitation(let from), .afterRecitation(let to)):
                    let gap = Duration.seconds(to - from)
                    try await soundBank.pauseGate.sleep(for: gap - overrun)
                    overrun = max(overrun - gap, .zero)
                case (.seconds, .afterRecitation(let seconds)):
                    await recitation.value
                    overrun = .zero
                    try await soundBank.pauseGate.sleep(for: .seconds(seconds))
                case (.afterRecitation, .seconds):
                    // The score reader doesn't allow a time from the start after one from the end.
                    break
                }
                // Play the stretch.
                let length: Duration
                switch (stretch.start, stretch.end) {
                case (.seconds(let from), .seconds(let to)), (.afterRecitation(let from), .afterRecitation(let to)):
                    length = .seconds(to - from) - overrun
                case (.seconds, .afterRecitation(let seconds)):
                    _ = try await soundBank.play(notes: &notes, instrument: instrument, volume: stretch.volume) { _ in !recited.isSet }
                    length = .seconds(seconds)
                case (.afterRecitation, .seconds):
                    length = .zero
                }
                let played = try await soundBank.play(notes: &notes, instrument: instrument, volume: stretch.volume) { $0 < length }
                overrun = max(played.reduce(Duration.zero) { $0 + $1.duration.duration } - length, .zero)
                position = stretch.end
                guard !Task.isCancelled else { break }
            }
        } catch is CancellationError {
        } catch {
            logger.error("Couldn't play \(event.instrument): \(String(describing: error))")
        }
        return notes
    }
}

/// Whether something has happened, which any task can check without waiting for it.
private final class Flag: Sendable {
    private let state = Mutex(false)

    var isSet: Bool {
        state.withLock { $0 }
    }

    func set() {
        state.withLock { $0 = true }
    }
}
