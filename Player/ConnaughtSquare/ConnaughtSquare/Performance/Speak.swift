//
//  Speak.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 26/12/2023.
//

import Foundation
import AVFoundation

final class Speak: Operation, @unchecked Sendable {
    let delegate: EventDelegate
    let synthesizer: AVSpeechSynthesizer
    let speaker: Speaker
	let part: Part
	
	override var isAsynchronous: Bool {
		return true
	}
	
	// TODO: What's going on here?
	
	private var _isExecuting = false {
		willSet {
			willChangeValue(forKey: "isExecuting")
		}
		didSet {
			didChangeValue(forKey: "isExecuting")
		}
	}
	
	override var isExecuting: Bool {
		return _isExecuting
	}
	
	private var _isFinished = false {
		willSet {
			willChangeValue(forKey: "isFinished")
		}
		didSet {
			didChangeValue(forKey: "isFinished")
		}
	}
	
	override var isFinished: Bool {
		return _isFinished
	}
	
	init(speaker: Speaker, part: Part, delegate: EventDelegate) {
		synthesizer = AVSpeechSynthesizer()
		self.speaker = speaker
        self.part = part
        self.delegate = delegate
		super.init()
		synthesizer.delegate = self
	}
	
	override func main() {
		guard isCancelled == false else {
			_isFinished = true
			return
		}
		_isExecuting = true
		if synthesizer.isSpeaking {
			synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
		}
		let utterance = AVSpeechUtterance(attributedString: part.nsAttributedString)
		utterance.voice = speaker.voice
		utterance.pitchMultiplier = 1
		utterance.rate = AVSpeechUtteranceDefaultSpeechRate
		utterance.volume = 1
		synthesizer.speak(utterance)
	}
}

// MARK: - AVSpeechSynthesizerDelegate
extension Speak: AVSpeechSynthesizerDelegate {
	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
		guard isCancelled == false else {
			synthesizer.stopSpeaking(at: .word)
			_isFinished = true
			return
		}
        delegate.didSpeak(part: part)
	}
	
	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
		guard isCancelled == false else {
			synthesizer.stopSpeaking(at: .word)
			_isFinished = true
			return
		}
	}
	
	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
		_isFinished = true
	}
}
