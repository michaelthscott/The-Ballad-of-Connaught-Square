//
//  PreviewBallad.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 26/03/2025.
//

import Foundation
import SwiftUI

struct PreviewBallad: PreviewModifier {
    static func makeSharedContext() async throws -> Ballad {
        let lines: [Line] = try decodeAsset("LinesPreview", from: Bundle.main)
        return Ballad(lines: lines, tags: LinguisticTagOrder(lines: lines))
    }
    
    func body(content: Content, context: Ballad) -> some View {
        content
            .environment(context)
    }
}
