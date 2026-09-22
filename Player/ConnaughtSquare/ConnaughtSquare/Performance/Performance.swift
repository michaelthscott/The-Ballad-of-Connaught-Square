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
@MainActor @Observable final class Performance {
    var spokenPartCount: Int = 0
	let ballad: Ballad
	let speakers: Speakers
    let composer: Composer
	var isFinished = false

    private let speech = SpeechSynthesizer()
    private let soundBank: SoundBank
    private var performanceTask: Task<Void, Never>?

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
    	
    /// Starts performing the ballad from the beginning. Does nothing if a performance is already running.
	func perform() {
        guard performanceTask == nil else { return }
        isFinished = false
        performanceTask = Task { [weak self] in
            await self?.run()
        }
	}
	
    /// Stops the performance, silencing the voices and the accompaniment.
    func stop() {
        performanceTask?.cancel()
        performanceTask = nil
        speech.stop()
        let soundBank = soundBank
        Task { await soundBank.stopEngine() }
        isFinished = true
    }

    private func run() async {
        var events = EventsSequence(performance: self)
        while !Task.isCancelled, let batch = events.next() {
            await perform(batch)
        }
        await soundBank.stopEngine()
        performanceTask = nil
        isFinished = true
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
                try? await Task.sleep(for: duration)
            }
        }
    }
}

/// The `Sendable` part of an event: the accompaniment that can be played off the main actor.
private enum Accompaniment: Sendable {
    case play(orchestration: Orchestration, duration: Duration)
    case silence(duration: Duration)
}
