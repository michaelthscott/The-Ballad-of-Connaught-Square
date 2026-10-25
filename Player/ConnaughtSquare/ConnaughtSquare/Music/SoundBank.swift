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
    case failedToConnectNodes
    case failedToStartEngine
}

/// The audio engine and samplers used to play notes.
///
/// Each instrument has its own sampler, so instruments played at the same time each sound with
/// their own preset, and stopping a note on one instrument doesn't stop the same pitch on another.
/// The samplers are mixed together and played through a shared reverb.
///
/// The engine and its nodes are isolated to this actor, so assignments played at the same time
/// are serialised on the samplers rather than racing on them. Because the actor is `Sendable`,
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
    /// Notes wait at this gate before sounding, and time their lengths against it, so pausing it
    /// holds a sounding note until it is resumed and stops further notes from starting.
    nonisolated let pauseGate = PauseGate()

    private let engine: AVAudioEngine
    private let mixer: AVAudioMixerNode
    private let reverb: AVAudioUnitReverb
    /// The sampler for each instrument that has been loaded.
    private var samplers: [InstrumentName: AVAudioUnitSampler] = [:]
    /// Whether the engine was running when it was paused, and so should be restarted on resume.
    private var isEnginePaused = false

    /// The instruments that have been loaded.
    var loadedInstruments: Set<InstrumentName> {
        Set(samplers.keys)
    }

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
        // The samplers are connected to the mixer as their instruments are loaded.
        let engine = AVAudioEngine()
        let mixer = AVAudioMixerNode()
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.smallRoom)
        reverb.wetDryMix = 100.0
        engine.attach(mixer)
        engine.attach(reverb)
        do {
            try engine.connectNode(mixer, to: reverb, format: nil)
            try engine.connectNode(reverb, to: engine.outputNode, format: nil)
        } catch {
            throw SoundBankError.failedToConnectNodes
        }
        self.engine = engine
        self.mixer = mixer
        self.reverb = reverb
    }

    /// Loads the instrument's preset into a sampler of its own.
    ///
    /// Does nothing if the instrument has already been loaded.
    func loadInstrument(_ name: InstrumentName) throws {
        guard samplers[name] == nil else { return }
        let sampler = AVAudioUnitSampler()
        engine.attach(sampler)
        // Mixer input buses can be connected while the engine is running, so instruments can be added mid-performance.
        do {
            try engine.connectNode(sampler, to: mixer, fromBus: 0, toBus: mixer.nextAvailableInputBus, format: nil)
        } catch {
            engine.detach(sampler)
            throw SoundBankError.failedToConnectNodes
        }
        let bankMSB = UInt8(kAUSampler_DefaultMelodicBankMSB)
        let bankLSB = UInt8(kAUSampler_DefaultBankLSB)
        let presetID = UInt8(name.rawValue)
        do {
            try sampler.loadSoundBankInstrument(at: url, program: presetID, bankMSB: bankMSB, bankLSB: bankLSB)
        } catch {
            engine.detach(sampler)
            throw SoundBankError.failedToLoadSoundBank
        }
        samplers[name] = sampler
    }

    var isEngineRunning: Bool {
        engine.isRunning
    }

    /// Starts the engine if it isn't running. Does nothing while the engine is paused, so an
    /// instrument starting to play can't unpause it; only `resumeEngine()` does that.
    func startEngine() throws {
        guard !engine.isRunning, !isEnginePaused else { return }
        do {
            try engine.start()
        } catch {
            throw SoundBankError.failedToStartEngine
        }
    }

    func stopEngine() {
        isEnginePaused = false
        if engine.isRunning {
            //TODO: How long does it take the engine to stop?
            engine.stop()
        }
    }

    /// Silences the engine immediately, keeping its resources so it can resume quickly.
    func pauseEngine() {
        guard engine.isRunning else { return }
        engine.pause()
        isEnginePaused = true
    }

    /// Restarts the engine if it was running when it was paused.
    func resumeEngine() throws {
        guard isEnginePaused else { return }
        isEnginePaused = false
        try startEngine()
    }

    /// Starts the note sounding on the instrument. Does nothing if the instrument hasn't been loaded.
    func startNote(_ note: Note, instrument: InstrumentName) {
        samplers[instrument]?.startNote(note.value.rawValue, withVelocity: note.on.rawValue, onChannel: 0)
    }

    /// Stops the note sounding on the instrument. Does nothing if the instrument hasn't been loaded.
    func stopNote(_ note: Note, instrument: InstrumentName) {
        samplers[instrument]?.stopNote(note.value.rawValue, onChannel: 0)
    }
}

extension SoundBank {
    /// Plays the note on the instrument for the length of its duration.
    ///
    /// This is `nonisolated` so that waiting out the note's duration doesn't block the actor,
    /// which lets notes from other instruments sound at the same time.
    /// - Note: Nothing sounds unless the instrument has been loaded and the engine started.
    nonisolated func play(note: Note, instrument: InstrumentName) async {
        await startNote(note, instrument: instrument)
        // Time paused doesn't count towards the note's length.
        // A cancelled sleep still falls through to `stopNote`, so a note is never left sounding.
        try? await pauseGate.sleep(for: note.duration.duration)
        await stopNote(note, instrument: instrument)
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
            await pauseGate.wait()
            guard !Task.isCancelled else { break }
            let note = notes.next()
            await play(note: note, instrument: instrument)
            durationPlayed += note.duration.duration
            played.append(note)
        }
        return played
    }
}
