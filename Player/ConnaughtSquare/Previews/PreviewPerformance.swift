//
//  PreviewPerformance.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 28/03/2025.
//

import Foundation
import SwiftUI

struct PreviewPerformance: PreviewModifier {
    static func makeSharedContext() async throws -> Performance {
        Performance()
    }
    
    func body(content: Content, context: Performance) -> some View {
        content
            .environment(context)
    }
}
