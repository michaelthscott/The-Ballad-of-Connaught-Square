//
//  Performance.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 17/01/2024.
//

import Foundation

/// A performance of the ballad with musical accompaniment.
///
/// The performance runs as a single cancellable task on the main actor. Each batch of events
/// recites its parts on the main actor while its accompaniment plays in a child task off it,
/// and the batch finishes when both are done.
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
    let composer: Composer
    private(set) var state: PlaybackState = .stopped

    private let speech = SpeechSynthesizer()
    private let soundBank: SoundBank
    private var performanceTask: Task<Void, Never>?
    /// The most recent change to the audio engine. Each change waits for the previous one, so the
    /// engine is paused, resumed and stopped in the order they were requested.
    private var engineControlTask: Task<Void, Never>?

    init(composer: Composer = Composer(),
         ballad: Ballad = Ballad(),
         speakers: Speakers = Speakers(),
         soundBank: SoundBank = .shared) {
		self.ballad = ballad
        self.speakers = speakers
        self.composer = composer
        self.soundBank = soundBank
	}
	
    func orchestration(duration: Duration) -> Orchestration {
        composer.composeOrchestration("The Ballad of Connaught Square",
                                      instruments: [Instrument(name: .violin), Instrument(name: .viola), Instrument(name: .cello)],
                                      duration: duration)
    }
    	
    /// Starts performing the ballad from the beginning, or resumes a paused performance.
    /// Does nothing if the performance is already playing.
	func play() {
        switch state {
        case .stopped:
            ballad.isRecited = false
            speakers.resetTurns()
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
        controlEngine { try? await $0.resumeEngine() }
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
        while !Task.isCancelled, let batch = events.next() {
            await soundBank.pauseGate.wait()
            guard !Task.isCancelled else { break }
            await perform(batch)
        }
        // A cancelled performance was stopped, and `stop()` has already tidied up — possibly
        // before a new performance started, which this mustn't disturb.
        guard !Task.isCancelled else { return }
        performanceTask = nil
        controlEngine { await $0.stopEngine() }
        state = .stopped
    }

    /// Performs one batch of events, returning when both the accompaniment and the recitation have finished.
    private func perform(_ events: [Event]) async {
        var accompaniment: [Accompaniment] = []
        var recitation: [(part: Part, speaker: Speaker)] = []
        for event in events {
            print(event.description)
            switch event {
            case .play(let orchestration, let duration):
                accompaniment.append(.play(orchestration: orchestration, duration: duration))
            case .silence(let duration):
                accompaniment.append(.silence(duration: duration))
            case .speak(let part, let speaker):
                recitation.append((part, speaker))
            }
        }

        // The accompaniment is `Sendable`, so it plays in a child task off the main actor while
        // the parts — which aren't — are recited on it.
        let soundBank = soundBank
        async let played: Void = Self.play(accompaniment, on: soundBank)
        for (part, speaker) in recitation {
            await soundBank.pauseGate.wait()
            guard !Task.isCancelled else { break }
            await recite(part, as: speaker)
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

    /// Plays the accompaniment for a batch in order. `nonisolated` so it runs off the main actor.
    private nonisolated static func play(_ accompaniment: [Accompaniment], on soundBank: SoundBank) async {
        for item in accompaniment {
            guard !Task.isCancelled else { return }
            switch item {
            case .play(let orchestration, let duration):
                await orchestration.play(duration: duration, on: soundBank)
            case .silence(let duration):
                try? await soundBank.pauseGate.sleep(for: duration)
            }
        }
    }
}

/// The `Sendable` part of an event: the accompaniment that can be played off the main actor.
private enum Accompaniment: Sendable {
    case play(orchestration: Orchestration, duration: Duration)
    case silence(duration: Duration)
}
