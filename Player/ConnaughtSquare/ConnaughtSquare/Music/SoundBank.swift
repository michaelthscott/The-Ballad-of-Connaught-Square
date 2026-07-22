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

final class SoundBank {
    //TODO: How can we avoid having to mark this as nonisolated(unsafe)?
    nonisolated(unsafe) static let shared: SoundBank = {
        do{
            return try SoundBank()
        } catch {
            fatalError(error.localizedDescription)
        }
    }()

    let resource: String
    let suffix: String
    let url: URL
    let engine: AVAudioEngine
    let sampler: AVAudioUnitSampler
    let reverb: AVAudioUnitReverb

    convenience init() throws {
        // This is in the main bundle rather than the asset catalogue because we can't get an asset's URL.
        try self.init(resource: "GeneralUser GS MuseScore v1.442", suffix: "sf2")
    }
    
    init(resource: String, suffix: String) throws {
        self.resource = resource
        self.suffix = suffix
        engine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.smallRoom)
        reverb.wetDryMix = 100.0
        engine.attach(sampler)
        engine.attach(reverb)
        engine.connect(sampler, to: reverb, format: nil)
        engine.connect(reverb, to: engine.outputNode, format: nil)

        guard let url = Bundle.main.url(forResource: resource, withExtension: suffix) else {
            throw SoundBankError.failedToFindSoundBank
        }
        self.url = url
    }

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
    
    func startEngine() throws -> Bool {
        guard !engine.isRunning else { return true }
        do {
            try engine.start()
        } catch {
            throw SoundBankError.failedToStartEngine
        }
        return true
    }
    
    func stopEngine() {
        if engine.isRunning {
            //TODO: How long does it take the engine to stop?
            engine.stop()
        }
    }
    
    func play(note: Note) {
        sampler.startNote(note.value.rawValue, withVelocity: note.on.rawValue, onChannel: 0)
        usleep(note.duration.rawValue)
        sampler.stopNote(note.value.rawValue, onChannel: 0)
    }

    func play(notes: Cycle<Note>, duration: Duration) throws -> [Note] {
        guard try startEngine() else { return [] }
        var durationPlayed: Duration = .zero
        var notes = notes
        var played: [Note] = []
        while durationPlayed < duration {
            let note = notes.next()
            play(note: note)
            durationPlayed += note.duration.duration
            played.append(note)
        }
        return played
    }
}
