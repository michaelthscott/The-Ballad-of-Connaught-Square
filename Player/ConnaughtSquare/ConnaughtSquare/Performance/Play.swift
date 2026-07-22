//
//  Play.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 07/04/2025.
//

import Foundation
import AVFoundation

final class Play: Operation, @unchecked Sendable {
    let delegate: EventDelegate
    let orchestration: Orchestration
    let duration: Duration
    
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
    
    init(orchestration: Orchestration, duration: Duration, delegate: EventDelegate) {
        self.orchestration = orchestration
        self.duration = duration
        self.delegate = delegate
        super.init()
    }
    
    override func main() {
        guard isCancelled == false else {
            _isFinished = true
            return
        }
        _isExecuting = true
        orchestration.play(duration: duration)
        delegate.didPlay()
        _isFinished = true
    }
}

