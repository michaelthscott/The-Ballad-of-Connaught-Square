//
//  PreviewSpeakers.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 26/03/2025.
//

import Foundation
import SwiftUI

struct PreviewSpeakers: PreviewModifier {
    static func makeSharedContext() async throws -> Speakers {
        Speakers(roles: Score.bundled.voices.roles)
    }
    
    func body(content: Content, context: Speakers) -> some View {
        content
            .environment(context)
    }
}
