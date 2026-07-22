//
//  Phoneme.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 06/10/2023.
//

import Foundation

/// The type of articulation of a phoneme.
enum Articulation {
    case affricate
    case aspirate
    case fricative
    case liquid
    case nasal
    case semivowel
    case stop
    case vowel
}

// https://en.wikipedia.org/wiki/ARPABET

/// An ARPABET representation of a phoneme.
enum SpeechSound: String, Codable {
    case AA
    case AE
    case AH
    case AO
    case AW
    case AY
    case B
    case CH
    case D
    case DH
    case EH
    case ER
    case EY
    case F
    case G
    case HH
    case IH
    case IY
    case JH
    case K
    case L
    case M
    case N
    case NG
    case OW
    case OY
    case P
    case R
    case S
    case SH
    case T
    case TH
    case UH
    case UW
    case V
    case W
    case Y
    case Z
    case ZH
}

/// The types of stress used in a phoneme.
enum LexicalStress: Int, Codable {
    case noStress
    case primaryStress
    case secondaryStress
}

/// A unit of speech.
struct Phoneme {
    static func articulation(for sound: SpeechSound) -> Articulation {
        switch sound {
        case .AA:
            return .vowel
        case .AE:
            return .vowel
        case .AH:
            return .vowel
        case .AO:
            return .vowel
        case .AW:
            return .vowel
        case .AY:
            return .vowel
        case .B:
            return .stop
        case .CH:
            return .affricate
        case .D:
            return .stop
        case .DH:
            return .fricative
        case .EH:
            return .vowel
        case .ER:
            return .vowel
        case .EY:
            return .vowel
        case .F:
            return .fricative
        case .G:
            return .stop
        case .HH:
            return .aspirate
        case .IH:
            return .vowel
        case .IY:
            return .vowel
        case .JH:
            return .affricate
        case .K:
            return .stop
        case .L:
            return .liquid
        case .M:
            return .nasal
        case .N:
            return .nasal
        case .NG:
            return .nasal
        case .OW:
            return .vowel
        case .OY:
            return .vowel
        case .P:
            return .stop
        case .R:
            return .liquid
        case .S:
            return .fricative
        case .SH:
            return .fricative
        case .T:
            return .stop
        case .TH:
            return .fricative
        case .UH:
            return .vowel
        case .UW:
            return .vowel
        case .V:
            return .fricative
        case .W:
            return .semivowel
        case .Y:
            return .semivowel
        case .Z:
            return .fricative
        case .ZH:
            return .fricative
        }
    }

    let sound: SpeechSound
    let stress: LexicalStress?

    init(sound: SpeechSound, stress: LexicalStress? = nil) {
        self.sound = sound
        if Phoneme.articulation(for: sound) == .vowel {
            self.stress = stress
        } else {
            self.stress = nil
        }
    }

    var articulation: Articulation {
        return Phoneme.articulation(for: sound)
    }

    var isVowel: Bool {
        return articulation == .vowel
    }

    var isConsonant: Bool {
        return !isVowel
    }
    
    var ipa: String {
        switch sound {
        case .AA:
            return "ɑ"
        case .AE:
            return "æ"
        case .AH:
            return "ʌ"
        case .AO:
            return "ɔ"
        case .AW:
            return "aʊ"
        case .AY:
            return "aɪ"
        case .B:
            return "b"
        case .CH:
            return "ʧ"
        case .D:
            return "d"
        case .DH:
            return "ð"
        case .EH:
            return "ɛ"
        case .ER:
            return "ər"
        case .EY:
            return "e"
        case .F:
            return "f"
        case .G:
            return "g"
        case .HH:
            return "h"
        case .IH:
            return "ɪ"
        case .IY:
            return "i"
        case .JH:
            return "ʤ"
        case .K:
            return "k"
        case .L:
            return "l"
        case .M:
            return "m"
        case .N:
            return "n"
        case .NG:
            return "ŋ"
        case .OW:
            return "oʊ"
        case .OY:
            return "ɔɪ"
        case .P:
            return "p"
        case .R:
            return "ɹ"
        case .S:
            return "s"
        case .SH:
            return "ʃ"
        case .T:
            return "t"
        case .TH:
            return "θ"
        case .UH:
            return "ʊ"
        case .UW:
            return "u"
        case .V:
            return "v"
        case .W:
            return "w"
        case .Y:
            return "j"
        case .Z:
            return "z"
        case .ZH:
            return "ʒ"
        }
    }
}

// MARK: - Codable
extension Phoneme: Codable {}

// MARK: - Equatable
extension Phoneme: Equatable {}

// MARK: - Hashable
extension Phoneme: Hashable {}

// MARK: - CustomStringConvertible
extension Phoneme: CustomStringConvertible {
    var description: String {
        var string = sound.rawValue
        if let stress = stress {
            string += String(stress.rawValue)
        }
        return string
    }
}
