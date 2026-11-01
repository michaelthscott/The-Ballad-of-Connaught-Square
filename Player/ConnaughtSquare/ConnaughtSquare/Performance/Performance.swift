//
//  Performance.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 17/01/2024.
//

import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ConnaughtSquare", category: "Performance")

/// A performance of the ballad with musical accompaniment.
///
/// The performance runs as a single cancellable task on the main actor, performing one cue for each
/// part as the score notates it. The accompaniment before the part plays first; then the part is
/// recited on the main actor while the accompaniment under it plays in a child task off it, and the
/// cue finishes when both are done.
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
    let ballad: Ballad
    let speakers: Speakers
    let score: Score
    let arranger: Arranger
    private(set) var state: PlaybackState = .stopped

    private let speech = SpeechSynthesizer()
    private let soundBank: SoundBank
    private var performanceTask: Task<Void, Never>?
    /// The most recent change to the audio engine. Each change waits for the previous one, so the
    /// engine is paused, resumed and stopped in the order they were requested.
    private var engineControlTask: Task<Void, Never>?

    /// Creates a performance of the ballad as the score notates it.
    /// - Parameters:
    ///   - score: The score.
    ///   - ballad: The ballad.
    ///   - speakers: The voices for the score's roles. By default, a voice is chosen for each of its roles.
    ///   - soundBank: The sound bank to play on.
    init(score: Score = .bundled,
         ballad: Ballad = Ballad(),
         speakers: Speakers? = nil,
         soundBank: SoundBank = .shared) {
        self.score = score
        arranger = Arranger(score: score)
        self.ballad = ballad
        self.speakers = speakers ?? Speakers(roles: score.voices.roles)
        self.soundBank = soundBank
    }

    /// Starts performing the ballad from the beginning, or resumes a paused performance.
    /// Does nothing if the performance is already playing.
    func play() {
        switch state {
        case .stopped:
            ballad.isRecited = false
            spokenPartCount = 0
            soundBank.pauseGate.resume()
            state = .playing
            performanceTask = Task { [weak self] in
                await self?.run()
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

    private func run() async {
        // The accompaniment starts the engine itself, outside the queue of engine changes, so let
        // the last performance's stop take effect first; otherwise it could stop this one's engine.
        await engineControlTask?.value
        var events = EventsSequence(performance: self)
        while !Task.isCancelled, let cue = events.next() {
            await soundBank.pauseGate.wait()
            guard !Task.isCancelled else { break }
            await perform(cue)
        }
        // A cancelled performance was stopped, and `stop()` has already tidied up — possibly
        // before a new performance started, which this mustn't disturb.
        guard !Task.isCancelled else { return }
        performanceTask = nil
        controlEngine { await $0.stopEngine() }
        state = .stopped
    }

    /// Performs one cue, returning when both the accompaniment and the recitation have finished.
    ///
    /// The accompaniment before the part finishes before it is recited. The accompaniment under
    /// the part starts as it is recited.
    private func perform(_ cue: Cue) async {
        logger.debug("\(cue.description)")
        let soundBank = soundBank
        // The accompaniment is `Sendable`, so it plays off the main actor while the part — which
        // isn't — is recited on it. Time paused doesn't count towards it.
        await Self.play(cue.before, on: soundBank, until: nil)
        guard !Task.isCancelled else { return }
        // The recitation is a task of its own, so that accompaniment lasting as long as the part
        // can wait for it to finish. It runs on the main actor, as this does.
        let part = cue.part
        let speaker = cue.speaker
        let recitation = Task {
            await soundBank.pauseGate.wait()
            guard !Task.isCancelled else { return }
            await self.recite(part, as: speaker)
        }
        // Take the events out of the cue first, so the child task doesn't capture its part.
        let under = cue.under
        async let played: Void = Self.play(under, on: soundBank, until: recitation)
        await withTaskCancellationHandler {
            await recitation.value
        } onCancel: {
            recitation.cancel()
        }
        await played
    }

    /// Recites the part in the speaker's voice.
    ///
    /// The part is marked as recited before speech begins so that the text appears as it is spoken.
    private func recite(_ part: Part, as speaker: Speaker) async {
        part.isRecited = true
        spokenPartCount += 1
        await speech.speak(part.nsAttributedString, in: speaker.voice)
    }

    /// Plays the accompaniment in order. `nonisolated` so it runs off the main actor.
    /// - Parameters:
    ///   - accompaniment: The events to play.
    ///   - soundBank: The sound bank to play on.
    ///   - recitation: The recitation that accompaniment lasting as long as the part plays until, or
    ///     `nil` before the part, when there's no such accompaniment.
    private nonisolated static func play(_ accompaniment: [Event], on soundBank: SoundBank, until recitation: Task<Void, Never>?) async {
        for event in accompaniment {
            guard !Task.isCancelled else { return }
            switch event {
            case .play(let orchestration, let duration):
                await orchestration.play(duration: duration, on: soundBank)
            case .accompany(let orchestration):
                guard let recitation else { continue }
                await accompany(recitation, with: orchestration, on: soundBank)
            case .silence(let duration):
                try? await soundBank.pauseGate.sleep(for: duration)
            }
        }
    }

    /// Plays the orchestration until the recitation has finished, stopping its notes then. If the
    /// recitation has already finished, nothing plays.
    nonisolated static func accompany(_ recitation: Task<Void, Never>, with orchestration: Orchestration, on soundBank: SoundBank) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                // Longer than any part, so that it's the recitation that ends the accompaniment.
                await orchestration.play(duration: .seconds(24 * 60 * 60), on: soundBank)
            }
            group.addTask {
                await recitation.value
            }
            await group.next()
            group.cancelAll()
        }
    }
}
