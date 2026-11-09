//
//  SpeechSynthesizer.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 22/09/2026.
//

import Foundation
import AVFoundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ConnaughtSquare", category: "SpeechSynthesizer")

/// Speaks utterances through an audio engine, so that each voice can stand to one side in stereo.
///
/// `AVSpeechSynthesizer` can't pan the speech it plays, so instead its speech is written to audio
/// buffers, which are played through a player node panned to where the voice stands. `speak(_:in:pan:)`
/// returns once the last buffer has been heard.
///
/// Each voice speaks through a synthesizer and a player of its own, so the voices taking turns don't
/// make one synthesizer switch voice for every utterance, which can leave its audio stuttering as it
/// starts. Only one utterance is spoken at a time, whichever voice speaks it.
///
/// Speech is paused and stopped at once, rather than at the next word, because the buffers already
/// given to a player can't be stopped at a word.
@MainActor
final class SpeechSynthesizer {
    /// The synthesizer for each voice that has spoken, by the voice's identifier.
    private var synthesizers: [String: AVSpeechSynthesizer] = [:]
    /// The player for each voice that has spoken, by the voice's identifier.
    private var players: [String: AVAudioPlayerNode] = [:]
    /// The utterance being spoken, which pausing, resuming and stopping act on.
    private var current: Recitation?
    /// Whether speech is paused, so that speech starting or restarting stays paused until resumed.
    private var isPaused = false
    /// The engine is made with the first utterance, so that a performance that never speaks, such
    /// as one in a test, doesn't make an engine and watch its audio route.
    private lazy var engine: AVAudioEngine = makeEngine()
    /// Restarts the engine when a change to the audio route stops it.
    private var configurationChanges: Task<Void, Never>?

    /// Makes the engine, and starts watching for changes to its audio route.
    private func makeEngine() -> AVAudioEngine {
        let engine = AVAudioEngine()
        configurationChanges = Task { [weak self, engine] in
            for await _ in NotificationCenter.default.notifications(named: .AVAudioEngineConfigurationChange, object: engine) {
                self?.restartAfterConfigurationChange()
            }
        }
        return engine
    }

    isolated deinit {
        configurationChanges?.cancel()
    }

    /// Whether the output has two channels or more, so that voices can stand to either side.
    private var isStereo: Bool {
        engine.outputNode.outputFormat(forBus: 0).channelCount >= 2
    }

    /// The voice's synthesizer, made the first time the voice speaks.
    private func synthesizer(for voice: AVSpeechSynthesisVoice) -> AVSpeechSynthesizer {
        if let synthesizer = synthesizers[voice.identifier] {
            return synthesizer
        }
        let synthesizer = AVSpeechSynthesizer()
        synthesizers[voice.identifier] = synthesizer
        return synthesizer
    }

    /// The voice's player, connected to the main mixer in the format of its speech. A voice's
    /// first utterance attaches its player, and the player is connected again should the format change.
    private func player(for voice: AVSpeechSynthesisVoice, format: AVAudioFormat) throws -> AVAudioPlayerNode {
        let player = players[voice.identifier] ?? {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            players[voice.identifier] = player
            return player
        }()
        if engine.outputConnectionPoints(for: player, outputBus: 0).isEmpty || player.outputFormat(forBus: 0) != format {
            engine.disconnectNodeOutput(player)
            try engine.connectNode(player, to: engine.mainMixerNode, format: format)
        }
        return player
    }

    /// Speaks the attributed string in the given voice, returning once speech has finished.
    ///
    /// Cancelling the surrounding task stops the speech at once.
    /// - Parameters:
    ///   - attributedString: The text to speak, including any IPA pronunciation attributes.
    ///   - voice: The voice to speak in.
    ///   - pan: Where the voice stands in stereo, from -1 on the left to 1 on the right. It stands in
    ///     the centre when the output isn't stereo.
    func speak(_ attributedString: NSAttributedString, in voice: AVSpeechSynthesisVoice, pan: Float) async {
        if let current {
            stop(current)
        }
        guard !Task.isCancelled else { return }
        let synthesizer = synthesizer(for: voice)
        // A warm-up still being written would hold this utterance back until it finished.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(attributedString: attributedString)
        utterance.voice = voice
        utterance.pitchMultiplier = 1
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1

        let (buffers, continuation) = AsyncStream.makeStream(of: SpeechBuffer.self)
        let recitation = Recitation(synthesizer: synthesizer, pan: pan, buffers: continuation)
        current = recitation
        // The buffers arrive off the main actor, so the callback mustn't be isolated to it. A buffer
        // without any audio marks the end of the utterance.
        synthesizer.write(utterance) { @Sendable buffer in
            guard let buffer = buffer as? AVAudioPCMBuffer, buffer.frameLength > 0 else {
                continuation.finish()
                return
            }
            continuation.yield(SpeechBuffer(buffer: buffer))
        }

        await withTaskCancellationHandler {
            await play(buffers, in: voice, for: recitation)
        } onCancel: {
            Task { @MainActor in self.stop(recitation) }
        }
        if current === recitation {
            current = nil
        }
    }

    /// Plays the buffers as they arrive, returning once the last of them has been heard or the
    /// recitation has been stopped.
    ///
    /// The latest buffer is held back until the next arrives, so that the last can be waited for.
    private func play(_ buffers: AsyncStream<SpeechBuffer>, in voice: AVSpeechSynthesisVoice, for recitation: Recitation) async {
        var held: AVAudioPCMBuffer?
        for await next in buffers {
            guard current === recitation else { return }
            if recitation.player == nil {
                do {
                    let player = try player(for: voice, format: next.buffer.format)
                    recitation.player = player
                    player.pan = isStereo ? recitation.pan : 0
                    try startEngine()                } catch {
                    logger.error("Couldn't play \(voice.name): \(String(describing: error))")
                    stop(recitation)
                    return
                }
            }
            guard let player = recitation.player else { return }
            if let held {
                player.scheduleBuffer(held, atTime: nil, completionCallbackType: .dataConsumed, completionHandler: nil)
            }
            held = next.buffer
            guard play(recitation) else { return }
        }
        guard let held, let player = recitation.player, current === recitation else { return }
        // Stopping the player ends the wait as well as the buffer being heard.
        _ = await player.scheduleBuffer(held, completionCallbackType: .dataPlayedBack)
    }

    /// Plays the recitation's player unless speech is paused, returning whether it can carry on.
    /// A player that can't play stops the recitation, which would otherwise wait for it forever.
    private func play(_ recitation: Recitation) -> Bool {
        guard let player = recitation.player, !isPaused, !player.isPlaying else { return true }
        do {
            try player.playAudio()
            return true
        } catch {
            logger.error("Couldn't play the speech: \(String(describing: error))")
            stop(recitation)
            return false
        }
    }

    /// Starts the engine if it isn't running.
    private func startEngine() throws {
        guard !engine.isRunning else { return }
        try engine.start()
    }

    /// A change to the audio route, such as headphones being plugged in or out, stops the engine,
    /// so it's started again and the speech carries on, panned for the new output.
    private func restartAfterConfigurationChange() {
        guard let current, let player = current.player else { return }
        do {
            try startEngine()
        } catch {
            logger.error("Couldn't restart the speech engine: \(String(describing: error))")
            stop(current)
            return
        }
        player.pan = isStereo ? current.pan : 0
        _ = play(current)
    }

    /// Writes a few words in each voice without playing them, so that each synthesizer has its voice
    /// ready before its first utterance rather than starting it stuttering.
    ///
    /// The buffers are thrown away. This returns straight away, leaving the warm-ups to finish on
    /// their own. Nothing waits for them, and an utterance spoken in the same voice cuts its warm-up short.
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

    /// Stops any speech in progress at once.
    func stop() {
        isPaused = false
        if let current {
            stop(current)
        }
    }

    /// Stops the recitation if it's still the one being spoken, ending its `speak(_:in:pan:)`.
    private func stop(_ recitation: Recitation) {
        guard current === recitation else { return }
        current = nil
        recitation.synthesizer.stopSpeaking(at: .immediate)
        recitation.buffers.finish()
        recitation.player?.stop()
    }

    /// Pauses any speech in progress at once.
    ///
    /// A paused utterance hasn't finished, so `speak(_:in:pan:)` keeps waiting until it is resumed or stopped.
    func pause() {
        isPaused = true
        current?.player?.pause()
    }

    /// Continues speech from where it was paused.
    func resume() {
        guard isPaused else { return }
        isPaused = false
        if let current {
            _ = play(current)
        }
    }
}

/// An utterance being spoken: the synthesizer writing it, the player playing it, and where it stands.
@MainActor
private final class Recitation {
    let synthesizer: AVSpeechSynthesizer
    let pan: Float
    /// Finishing the buffers ends the wait for any more.
    let buffers: AsyncStream<SpeechBuffer>.Continuation
    /// The voice's player, once the first buffer has arrived.
    var player: AVAudioPlayerNode?

    init(synthesizer: AVSpeechSynthesizer, pan: Float, buffers: AsyncStream<SpeechBuffer>.Continuation) {
        self.synthesizer = synthesizer
        self.pan = pan
        self.buffers = buffers
    }
}

/// A buffer of speech, handed from the synthesizer's callback to the main actor. The synthesizer
/// doesn't touch a buffer once it has handed it over, so it's safe to send.
private struct SpeechBuffer: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
}
