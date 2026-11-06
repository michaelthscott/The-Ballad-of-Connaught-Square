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
    /// Core Audio aborts when samplers in different sound banks load presets at the same time, so
    /// presets are loaded one at a time across every sound bank, not just within this actor.
    private static let presetLoadingLock = NSLock()

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
            try Self.presetLoadingLock.withLock {
                try sampler.loadSoundBankInstrument(at: url, program: presetID, bankMSB: bankMSB, bankLSB: bankLSB)
            }
        } catch {
            engine.detach(sampler)
            throw SoundBankError.failedToLoadSoundBank
        }
        samplers[name] = sampler
    }

    /// Loads the instruments and starts the engine, so that they're ready before the first note.
    ///
    /// Otherwise each instrument loads its preset as it first plays, which can interrupt the
    /// instruments already playing and hold back its own first note.
    func warmUp(_ instruments: some Sequence<InstrumentName>) throws {
        for instrument in instruments {
            try loadInstrument(instrument)
        }
        try startEngine()
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

    /// Stops the engine and releases the samplers.
    ///
    /// Stopping the engine empties the samplers' presets, and starting it again leaves them playing
    /// the sampler's default sound, so the samplers are detached and each instrument is loaded afresh
    /// when it next plays.
    func stopEngine() {
        isEnginePaused = false
        if engine.isRunning {
            engine.stop()
        }
        for sampler in samplers.values {
            engine.detach(sampler)
        }
        samplers.removeAll()
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

    /// Starts the note sounding on the instrument at the volume. Does nothing if the instrument
    /// hasn't been loaded, or if the volume leaves the note silent, as a velocity of 0 would stop it.
    func startNote(_ note: Note, instrument: InstrumentName, volume: Double = 1) {
        let velocity = note.on.scaled(by: volume)
        guard velocity > 0 else { return }
        samplers[instrument]?.startNote(note.value.rawValue, withVelocity: velocity, onChannel: 0)
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
    nonisolated func play(note: Note, instrument: InstrumentName, volume: Double = 1) async {
        await startNote(note, instrument: instrument, volume: volume)
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
    ///   - volume: The volume between 0 and 1 that the notes' velocities are scaled by.
    /// - Returns: The notes played.
    nonisolated func play(notes: Cycle<Note>, duration: Duration, instrument: InstrumentName, volume: Double = 1) async throws -> [Note] {
        var notes = notes
        return try await play(notes: &notes, instrument: instrument, volume: volume) { $0 < duration }
    }

    /// Plays notes from the cycle one after another for as long as the condition holds, leaving the
    /// cycle at the next note to play, so the melody can carry on from there.
    /// - Parameters:
    ///   - notes: A cycle of notes, moved on past the notes played.
    ///   - instrument: The instrument whose preset the notes are played with.
    ///   - volume: The volume between 0 and 1 that the notes' velocities are scaled by.
    ///   - shouldContinue: Whether to play another note, given the length of the notes played so far.
    /// - Returns: The notes played.
    nonisolated func play(notes: inout Cycle<Note>, instrument: InstrumentName, volume: Double = 1, while shouldContinue: (Duration) -> Bool) async throws -> [Note] {
        try await loadInstrument(instrument)
        try await startEngine()
        var durationPlayed: Duration = .zero
        var played: [Note] = []
        while shouldContinue(durationPlayed), !Task.isCancelled {
            await pauseGate.wait()
            guard !Task.isCancelled else { break }
            let note = notes.next()
            await play(note: note, instrument: instrument, volume: volume)
            durationPlayed += note.duration.duration
            played.append(note)
        }
        return played
    }
}
