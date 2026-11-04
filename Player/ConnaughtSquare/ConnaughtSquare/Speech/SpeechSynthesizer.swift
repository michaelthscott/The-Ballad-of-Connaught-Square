//
//  SpeechSynthesizer.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 22/09/2026.
//

import Foundation
import AVFoundation

/// Bridges `AVSpeechSynthesizer`'s delegate callbacks to `async`/`await`.
///
/// `AVSpeechSynthesizer` has no asynchronous API, so `speak(_:in:)` wraps a single utterance
/// in a continuation that is resumed when the synthesizer either finishes or is cancelled.
///
/// Each voice speaks through a synthesizer of its own, so the voices taking turns don't make one
/// synthesizer switch voice for every utterance, which can leave its audio stuttering as it starts.
/// Only one utterance is spoken at a time, whichever synthesizer speaks it.
@MainActor
final class SpeechSynthesizer {
    /// The synthesizer for each voice that has spoken, by the voice's identifier.
    private var synthesizers: [String: AVSpeechSynthesizer] = [:]
    /// The synthesizer that spoke last, which pausing, resuming and stopping act on.
    private var current: AVSpeechSynthesizer?
    private let coordinator = Coordinator()

    /// The voice's synthesizer, made the first time the voice speaks.
    private func synthesizer(for voice: AVSpeechSynthesisVoice) -> AVSpeechSynthesizer {
        if let synthesizer = synthesizers[voice.identifier] {
            return synthesizer
        }
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = coordinator
        synthesizers[voice.identifier] = synthesizer
        return synthesizer
    }

    /// Speaks the attributed string in the given voice, returning once speech has finished.
    ///
    /// Cancelling the surrounding task stops the synthesizer at the next word boundary, which
    /// resumes the continuation via the delegate's cancellation callback.
    /// - Parameters:
    ///   - attributedString: The text to speak, including any IPA pronunciation attributes.
    ///   - voice: The voice to speak in.
    func speak(_ attributedString: NSAttributedString, in voice: AVSpeechSynthesisVoice) async {
        if let current, current.isSpeaking {
            current.stopSpeaking(at: .immediate)
        }
        let synthesizer = synthesizer(for: voice)
        // A warm-up still speaking would hold this utterance back until it finished.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        current = synthesizer
        let utterance = AVSpeechUtterance(attributedString: attributedString)
        utterance.voice = voice
        utterance.pitchMultiplier = 1
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1

        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                // A task cancelled before speech begins has already run its cancellation handler,
                // whose stop would find nothing to stop, so it mustn't start speaking at all.
                guard !Task.isCancelled else {
                    continuation.resume()
                    return
                }
                coordinator.begin(continuation, for: utterance)
                synthesizer.speak(utterance)
            }
        } onCancel: {
            Task { @MainActor in self.stop() }
        }
    }

    /// Synthesizes a few words in each voice without playing them, so that each synthesizer has its
    /// voice ready before its first utterance rather than starting it stuttering.
    ///
    /// The words are written to audio buffers that are thrown away, rather than spoken at no volume,
    /// which can still be faintly heard. This returns straight away, leaving the warm-ups to finish
    /// on their own. Nothing waits for them, and an utterance spoken in the same voice cuts its
    /// warm-up short.
    func warmUp(_ voices: [AVSpeechSynthesisVoice]) {
        for voice in voices {
            let synthesizer = synthesizer(for: voice)
            guard !synthesizer.isSpeaking else { continue }
            let utterance = AVSpeechUtterance(string: "Connaught Square")
            utterance.voice = voice
            // The buffers arrive off the main actor, so the callback mustn't be isolated to it.
            synthesizer.write(utterance) { @Sendable _ in }
        }
    }

    /// Stops any speech in progress at the next word boundary, or immediately if speech is paused.
    func stop() {
        if let current, current.isSpeaking {
            current.stopSpeaking(at: current.isPaused ? .immediate : .word)
        }
    }

    /// Pauses any speech in progress at the next word boundary.
    ///
    /// A paused utterance hasn't finished, so `speak(_:in:)` keeps waiting until it is resumed or stopped.
    func pause() {
        if let current, current.isSpeaking {
            current.pauseSpeaking(at: .word)
        }
    }

    /// Continues speech from where it was paused.
    func resume() {
        if let current, current.isPaused {
            current.continueSpeaking()
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

/// Resumes the pending continuation when its utterance ends.
///
/// The synthesizer's callbacks aren't guaranteed to arrive on the main actor, so the
/// continuation is guarded by a lock rather than by actor isolation.
private final class Coordinator: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var pending: (utterance: AVSpeechUtterance, continuation: CheckedContinuation<Void, Never>)?

    /// Waits for the utterance to end before resuming the continuation.
    ///
    /// Any utterance still pending has been superseded, so its continuation is resumed now rather
    /// than leaked; the callback that eventually arrives for it is then ignored.
    func begin(_ continuation: CheckedContinuation<Void, Never>, for utterance: AVSpeechUtterance) {
        let superseded = lock.withLock {
            defer { pending = (utterance, continuation) }
            return pending?.continuation
        }
        superseded?.resume()
    }

    /// Resumes the pending continuation if it belongs to the utterance. Matching the utterance stops
    /// a late callback for a stopped utterance from ending the one that replaced it, and resuming at
    /// most once makes it safe to receive both `didFinish` and `didCancel` for the same utterance.
    private func finish(_ utterance: AVSpeechUtterance) {
        let matched = lock.withLock { () -> CheckedContinuation<Void, Never>? in
            guard let pending, pending.utterance === utterance else { return nil }
            self.pending = nil
            return pending.continuation
        }
        matched?.resume()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finish(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finish(utterance)
    }
}
