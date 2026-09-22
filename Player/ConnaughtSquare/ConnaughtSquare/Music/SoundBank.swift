//
//  SoundBank.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/04/2025.
//

import Foundation
import AVFoundation

enum SoundBankError: Error {
    case failedToFindSoundBank
    case failedToLoadSoundBank
    case failedToStartEngine
}

/// The audio engine and sampler used to play notes.
///
/// The engine and its nodes are isolated to this actor, so assignments played at the same time
/// are serialised on the sampler rather than racing on it. Because the actor is `Sendable`,
/// `shared` no longer needs to be `nonisolated(unsafe)`.
actor SoundBank {
    static let shared: SoundBank = {
        do {
            return try SoundBank()
        } catch {
            fatalError(error.localizedDescription)
        }
    }()

    let resource: String
    let suffix: String
    let url: URL

    private let engine: AVAudioEngine
    private let sampler: AVAudioUnitSampler
    private let reverb: AVAudioUnitReverb

    /// Creates a sound bank from a SoundFont in the main bundle.
    ///
    /// The SoundFont is in the main bundle rather than the asset catalogue because we can't get an asset's URL.
    init(resource: String = "GeneralUser GS MuseScore v1.442", suffix: String = "sf2") throws {
        guard let url = Bundle.main.url(forResource: resource, withExtension: suffix) else {
            throw SoundBankError.failedToFindSoundBank
        }
        self.resource = resource
        self.suffix = suffix
        self.url = url

        // Build the graph locally, then adopt it, so the initialiser never touches isolated state.
        let engine = AVAudioEngine()
        let sampler = AVAudioUnitSampler()
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.smallRoom)
        reverb.wetDryMix = 100.0
        engine.attach(sampler)
        engine.attach(reverb)
        engine.connect(sampler, to: reverb, format: nil)
        engine.connect(reverb, to: engine.outputNode, format: nil)
        self.engine = engine
        self.sampler = sampler
        self.reverb = reverb
    }

    /// Loads the instrument's preset into the sampler.
    ///
    /// - Note: There is a single sampler, so the most recently loaded preset is the one that sounds.
    func loadInstrument(_ name: InstrumentName) throws {
        let bankMSB = UInt8(kAUSampler_DefaultMelodicBankMSB)
        let bankLSB = UInt8(kAUSampler_DefaultBankLSB)
        let presetID = UInt8(name.rawValue)
        do {
            try sampler.loadSoundBankInstrument(at: url, program: presetID, bankMSB: bankMSB, bankLSB: bankLSB)
        } catch {
            throw SoundBankError.failedToLoadSoundBank
        }
    }

    func startEngine() throws {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            throw SoundBankError.failedToStartEngine
        }
    }

    func stopEngine() {
        if engine.isRunning {
            //TODO: How long does it take the engine to stop?
            engine.stop()
        }
    }

    /// Starts the note sounding.
    func startNote(_ note: Note) {
        sampler.startNote(note.value.rawValue, withVelocity: note.on.rawValue, onChannel: 0)
    }

    /// Stops the note sounding.
    func stopNote(_ note: Note) {
        sampler.stopNote(note.value.rawValue, onChannel: 0)
    }
}

extension SoundBank {
    /// Plays the note for the length of its duration.
    ///
    /// This is `nonisolated` so that waiting out the note's duration doesn't block the actor,
    /// which lets notes from other instruments sound at the same time.
    nonisolated func play(note: Note) async {
        await startNote(note)
        // A cancelled sleep still falls through to `stopNote`, so a note is never left sounding.
        try? await Task.sleep(for: note.duration.duration)
        await stopNote(note)
    }

    /// Plays notes from the cycle until the specified duration has elapsed.
    /// - Parameters:
    ///   - notes: A cycle of notes.
    ///   - duration: A length of time.
    ///   - instrument: The instrument whose preset the notes are played with.
    /// - Returns: The notes played.
    nonisolated func play(notes: Cycle<Note>, duration: Duration, instrument: InstrumentName) async throws -> [Note] {
        try await loadInstrument(instrument)
        try await startEngine()
        var notes = notes
        var durationPlayed: Duration = .zero
        var played: [Note] = []
        while durationPlayed < duration, !Task.isCancelled {
            let note = notes.next()
            await play(note: note)
            durationPlayed += note.duration.duration
            played.append(note)
        }
        return played
    }
}
