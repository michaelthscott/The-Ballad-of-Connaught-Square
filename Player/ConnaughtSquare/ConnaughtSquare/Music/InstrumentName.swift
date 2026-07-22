//
//  InstrumentName.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 12/01/2024.
//

import Foundation

/// The names of the available instruments.
enum InstrumentName: UInt8 {
	case acousticGrandPiano = 0
	case brightAcousticPiano
	case electricGrandPiano
	case honkyTonkPiano
	case electricPiano1
	case electricPiano2
	case harpsichord
	case clavinet
	case celesta
	case glockenspiel
	case musicBox
	case vibraphone
	case marimba
	case xylophone
	case tubularBells
	case dulcimer
	case drawbarOrgan
	case percussiveOrgan
	case rockOrgan
	case churchOrgan
	case reedOrgan
	case accordion
	case harmonica
	case tangoAccordion
	case acousticGuitarNylon
	case acousticGuitarSteel
	case electricGuitarJazz
	case electricGuitarClean
	case electricGuitarMuted
	case overdrivenGuitar
	case distortionGuitar
	case guitarHarmonics
	case acousticBass
	case electricBassFinger
	case electricBassPick
	case fretlessBass
	case slapBass1
	case slapBass2
	case synthBass1
	case synthBass2
	case violin
	case viola
	case cello
	case contrabass
	case tremoloStrings
	case pizzicatoStrings
	case orchestralHarp
	case timpani
	case stringEnsemble1
	case stringEnsemble2
	case synthStrings1
	case synthStrings2
	case choirAahs
	case dooVoice
	case voiceOohs
	case orchestraHit
	case trumpet
	case trombone
	case tuba
	case mutedTrumpet
	case frenchHorn
	case brassSection
	case synthBrass1
	case synthBrass2
	case sopranoSax
	case altoSax
	case tenorSax
	case baritoneSax
	case oboe
	case englishHorn
	case bassoon
	case clarinet
	case piccolo
	case flute
	case recorder
	case panFlute
	case blownBottle
	case shakuhachi
	case whistle
	case ocarina
	case leadSquare
	case leadSawtooth
	case leadCalliope
	case leadChiff
	case leadCharang
	case leadVoice
	case leadFifths
	case leadBass
	case padNewAge
	case padWarm
	case padPolysynth
	case padChoir
	case padBowed
	case padMetalic
	case padHalo
	case padSweep
	case fxRain
	case fxSoundtrack
	case fxCrystal
	case fxAtmosphere
	case fxBrightness
	case fxGoblins
	case fxEchoes
	case fxSciFi
	case sitar
	case banjo
	case shamisen
	case koto
	case kalimba
	case bagpipe
	case fiddle
	case shanai
	case tinkleBell
	case agogo
	case steelDrums
	case woodblock
	case taikoDrum
	case melodicTom
	case synthDrum
	case reverseCymbal
	case guitarFretNoise
	case breathNoise
	case seashore
	case birdTweet
	case telephoneRing
	case helicopter
	case applause
	case gunshot
}

extension InstrumentName: CustomStringConvertible {
	var description: String {
		switch self {
		case .acousticGrandPiano:
			return "Acoustic Grand Piano"
		case .brightAcousticPiano:
			return "Bright Acoustic Piano"
		case .electricGrandPiano:
			return "Electric Grand Piano"
		case .honkyTonkPiano:
			return "Honky Tonk Piano"
		case .electricPiano1:
			return "Electric Piano 1"
		case .electricPiano2:
			return "Electric Piano 2"
		case .harpsichord:
			return "Harpsichord"
		case .clavinet:
			return "Clavinet"
		case .celesta:
			return "Celesta"
		case .glockenspiel:
			return "Glockenspiel"
		case .musicBox:
			return "Music Box"
		case .vibraphone:
			return "Vibraphone"
		case .marimba:
			return "Marimba"
		case .xylophone:
			return "Xylophone"
		case .tubularBells:
			return "Tubular Bells"
		case .dulcimer:
			return "Dulcimer"
		case .drawbarOrgan:
			return "Drawbar Organ"
		case .percussiveOrgan:
			return "Percussive Organ"
		case .rockOrgan:
			return "Rock Organ"
		case .churchOrgan:
			return "Church Organ"
		case .reedOrgan:
			return "Reed Organ"
		case .accordion:
			return "Accordion"
		case .harmonica:
			return "Harmonica"
		case .tangoAccordion:
			return "Tango Accordion"
		case .acousticGuitarNylon:
			return "Acoustic Guitar Nylon"
		case .acousticGuitarSteel:
			return "Acoustic Guitar Steel"
		case .electricGuitarJazz:
			return "Electric Guitar Jazz"
		case .electricGuitarClean:
			return "Electric Guitar Clean"
		case .electricGuitarMuted:
			return "Electric Guitar Muted"
		case .overdrivenGuitar:
			return "Overdriven Guitar"
		case .distortionGuitar:
			return "Distortion Guitar"
		case .guitarHarmonics:
			return "Guitar Harmonics"
		case .acousticBass:
			return "Acoustic Bass"
		case .electricBassFinger:
			return "Electric Bass Finger"
		case .electricBassPick:
			return "Electric Bass Pick"
		case .fretlessBass:
			return "Fretless Bass"
		case .slapBass1:
			return "Slap Bass 1"
		case .slapBass2:
			return "Slap Bass 2"
		case .synthBass1:
			return "Synth Bass 1"
		case .synthBass2:
			return "Synth Bass 2"
		case .violin:
			return "Violin"
		case .viola:
			return "Viola"
		case .cello:
			return "Cello"
		case .contrabass:
			return "Contrabass"
		case .tremoloStrings:
			return "Tremolo Strings"
		case .pizzicatoStrings:
			return "Pizzicato Strings"
		case .orchestralHarp:
			return "Orchestra lHarp"
		case .timpani:
			return "Timpani"
		case .stringEnsemble1:
			return "String Ensemble 1"
		case .stringEnsemble2:
			return "String Ensemble 2"
		case .synthStrings1:
			return "Synth Strings 1"
		case .synthStrings2:
			return "Synth Strings 2"
		case .choirAahs:
			return "Choir Aahs"
		case .dooVoice:
			return "Doo Voice"
		case .voiceOohs:
			return "Voice Oohs"
		case .orchestraHit:
			return "Orchestra Hit"
		case .trumpet:
			return "Trumpet"
		case .trombone:
			return "Trombone"
		case .tuba:
			return "Tuba"
		case .mutedTrumpet:
			return "Muted Trumpet"
		case .frenchHorn:
			return "French Horn"
		case .brassSection:
			return "Brass Section"
		case .synthBrass1:
			return "Synth Brass 1"
		case .synthBrass2:
			return "Synth Brass 2"
		case .sopranoSax:
			return "Soprano Sax"
		case .altoSax:
			return "Alto Sax"
		case .tenorSax:
			return "Tenor Sax"
		case .baritoneSax:
			return "Baritone Sax"
		case .oboe:
			return "Oboe"
		case .englishHorn:
			return "English Horn"
		case .bassoon:
			return "Bassoon"
		case .clarinet:
			return "Clarinet"
		case .piccolo:
			return "Piccolo"
		case .flute:
			return "Flute"
		case .recorder:
			return "Recorder"
		case .panFlute:
			return "Pan Flute"
		case .blownBottle:
			return "Blown Bottle"
		case .shakuhachi:
			return "Shakuhachi"
		case .whistle:
			return "Whistle"
		case .ocarina:
			return "Ocarina"
		case .leadSquare:
			return "Lead Square"
		case .leadSawtooth:
			return "Lead Sawtooth"
		case .leadCalliope:
			return "Lead Calliope"
		case .leadChiff:
			return "Lead Chiff"
		case .leadCharang:
			return "Lead Charang"
		case .leadVoice:
			return "Lead Voice"
		case .leadFifths:
			return "Lead Fifths"
		case .leadBass:
			return "Lead Bass"
		case .padNewAge:
			return "Pad New Age"
		case .padWarm:
			return "Pad Warm"
		case .padPolysynth:
			return "Pad Warm"
		case .padChoir:
			return "Pad Choir"
		case .padBowed:
			return "Pad Bowed"
		case .padMetalic:
			return "Pad Metalic"
		case .padHalo:
			return "Pad Halo"
		case .padSweep:
			return "Pad Sweep"
		case .fxRain:
			return "FX Rain"
		case .fxSoundtrack:
			return "FX Soundtrack"
		case .fxCrystal:
			return "FX Crystal"
		case .fxAtmosphere:
			return "FX Atmosphere"
		case .fxBrightness:
			return "FX Brightness"
		case .fxGoblins:
			return "FX Goblins"
		case .fxEchoes:
			return "FX Echoes"
		case .fxSciFi:
			return "FX SciFi"
		case .sitar:
			return "Sitar"
		case .banjo:
			return "Banjo"
		case .shamisen:
			return "Shamisen"
		case .koto:
			return "Koto"
		case .kalimba:
			return "Kalimba"
		case .bagpipe:
			return "Bagpipe"
		case .fiddle:
			return "Fiddle"
		case .shanai:
			return "Shanai"
		case .tinkleBell:
			return "Tinkle Bell"
		case .agogo:
			return "Agogo"
		case .steelDrums:
			return "Steel Drums"
		case .woodblock:
			return "Woodblock"
		case .taikoDrum:
			return "Taiko Drum"
		case .melodicTom:
			return "Melodic Tom"
		case .synthDrum:
			return "Synth Drum"
		case .reverseCymbal:
			return "Reverse Cymbal"
		case .guitarFretNoise:
			return "Guitar Fret Noise"
		case .breathNoise:
			return "Breath Noise"
		case .seashore:
			return "Seashore"
		case .birdTweet:
			return "Bird Tweet"
		case .telephoneRing:
			return "Telephone Ring"
		case .helicopter:
			return "Helicopter"
		case .applause:
			return "Applause"
		case .gunshot:
			return "Gunshot"
		}
	}
}

