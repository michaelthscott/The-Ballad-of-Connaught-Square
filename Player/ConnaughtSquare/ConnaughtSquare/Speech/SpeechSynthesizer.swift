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
                coordinator.begin(continuation)
                synthesizer.speak(utterance)
            }
        } onCancel: {
            Task { @MainActor in self.stop() }
        }
    }

    /// Stops any speech in progress at the next word boundary.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

/// Resumes the pending continuation when an utterance ends.
///
/// The synthesizer's callbacks aren't guaranteed to arrive on the main actor, so the
/// continuation is guarded by a lock rather than by actor isolation.
private final class Coordinator: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?

    func begin(_ continuation: CheckedContinuation<Void, Never>) {
        lock.withLock { self.continuation = continuation }
    }

    /// Resumes the pending continuation, if any. Resuming at most once is what makes it safe
    /// to receive both `didFinish` and `didCancel` for the same utterance.
    private func finish() {
        let pending = lock.withLock {
            defer { continuation = nil }
            return continuation
        }
        pending?.resume()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finish()
    }
}
