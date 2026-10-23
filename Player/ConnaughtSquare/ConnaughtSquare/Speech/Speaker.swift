//
//  Speaker.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 26/11/2023.
//

import Foundation
import AVFoundation

struct Speaker {
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
    /// Speakers are ordered by name, and by identifier when different voices share a name, so that
    /// the ordering agrees with equality.
    static func < (lhs: Speaker, rhs: Speaker) -> Bool {
        (lhs.name, lhs.id) < (rhs.name, rhs.id)
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
