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
@MainActor
final class SpeechSynthesizer {
    private let synthesizer = AVSpeechSynthesizer()
    private let coordinator = Coordinator()

    init() {
        synthesizer.delegate = coordinator
    }

    /// Speaks the attributed string in the given voice, returning once speech has finished.
    ///
    /// Cancelling the surrounding task stops the synthesizer at the next word boundary, which
    /// resumes the continuation via the delegate's cancellation callback.
    /// - Parameters:
    ///   - attributedString: The text to speak, including any IPA pronunciation attributes.
    ///   - voice: The voice to speak in.
    func speak(_ attributedString: NSAttributedString, in voice: AVSpeechSynthesisVoice) async {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
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

    /// Stops any speech in progress at the next word boundary, or immediately if speech is paused.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: synthesizer.isPaused ? .immediate : .word)
        }
    }

    /// Pauses any speech in progress at the next word boundary.
    ///
    /// A paused utterance hasn't finished, so `speak(_:in:)` keeps waiting until it is resumed or stopped.
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
    }

    /// Continues speech from where it was paused.
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
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
