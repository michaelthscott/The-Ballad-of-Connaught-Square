//
//  EventDelegate.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 07/04/2025.
//

import Foundation

protocol EventDelegate {
    func didSpeak(part: Part) -> Void
    func didPlay() -> Void
    func wasSilent() -> Void
}
