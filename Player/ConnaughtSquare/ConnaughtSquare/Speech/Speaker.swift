//
//  Speaker.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 26/11/2023.
//

import Foundation
import AVFoundation

final class Speaker {
    let voice: AVSpeechSynthesisVoice

    init(voice: AVSpeechSynthesisVoice) {
        self.voice = voice
    }
    
    var name: String {
        voice.name
    }
}

extension Speaker: Identifiable {
    typealias ID = String

    var id: String {
        voice.identifier
    }
}

extension Speaker: Equatable {
    static func == (lhs: Speaker, rhs: Speaker) -> Bool {
        lhs.id == rhs.id
    }
}

extension Speaker: Comparable {
    static func < (lhs: Speaker, rhs: Speaker) -> Bool {
        lhs.name < rhs.name
    }
}

extension Speaker: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Speaker: CustomStringConvertible {
    var description: String {
        name
    }
}
