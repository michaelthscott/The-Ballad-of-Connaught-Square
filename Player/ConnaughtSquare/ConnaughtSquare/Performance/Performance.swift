//
//  Performance.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 17/01/2024.
//

import Foundation

// A performance of the ballad with musical accompaniment.
@Observable final class Performance: EventDelegate {
    var spokenPartCount: Int = 0
	let ballad: Ballad
	let speakers: Speakers
    let composer: Composer!
    var eventsSequence: EventsSequence!
    var speechQueue: OperationQueue!
    var musicQueue: OperationQueue!
	var isFinished = false

    convenience init() {
        self.init(composer: Composer(), ballad: Ballad(), speakers: Speakers())
    }
    
    init(composer: Composer, ballad: Ballad, speakers: Speakers) {
		self.ballad = ballad
        self.speakers = speakers
        self.composer = composer
        // TODO: Is there an alternative to needing a new queue each time?
        speechQueue = OperationQueue()
        speechQueue.name = "Speech Queue"
        speechQueue.qualityOfService = .userInitiated
        musicQueue = OperationQueue()
        musicQueue.name = "Music Queue"
        musicQueue.qualityOfService = .userInitiated
        eventsSequence = EventsSequence(performance: self)
	}
	
    func orchestration(duration: Duration) -> Orchestration {
        composer.composeOrchestration("The Ballad of Connaught Square",
                                      instruments: [Instrument(name: .violin), Instrument(name: .viola), Instrument(name: .cello)],
                                      duration: duration)
    }
    	
	func perform() {
		performNextEvents()
        speechQueue.isSuspended = false
        musicQueue.isSuspended = false
	}
	
	func performNextEvents() {
        guard let events = eventsSequence.next() else {
			isFinished = true
			return
		}
        for event in events {
            print(event.description)
            switch event {
            case .speak(let part, let speaker):
                let operation = Speak(speaker: speaker, part: part, delegate: self)
                if let last = speechQueue.operations.last {
                    operation.addDependency(last)
                }
                speechQueue.addOperation(operation)
            case .play(let orchestration, let duration):
                let operation = Play(orchestration: orchestration, duration: duration, delegate: self)
                if let last = musicQueue.operations.last {
                    operation.addDependency(last)
                }
                musicQueue.addOperation(operation)
            case .silence(let duration):
                let operation = Silence(duration: duration, delegate: self)
                if let last = musicQueue.operations.last {
                    operation.addDependency(last)
                }
                musicQueue.addOperation(operation)
            }
        }
	}
	
	func didSpeak(part: Part) -> Void {
		part.isRecited = true
        spokenPartCount += 1
		performNextEvents()
	}
    
    func didPlay() -> Void {
        performNextEvents()
    }
    
    func wasSilent() -> Void {
        performNextEvents()
    }
    
    func stop() {
        speechQueue.cancelAllOperations()
        musicQueue.cancelAllOperations()
        isFinished = true
    }
}
