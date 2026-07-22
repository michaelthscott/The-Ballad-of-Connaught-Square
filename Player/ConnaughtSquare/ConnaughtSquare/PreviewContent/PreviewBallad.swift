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
        guard let lines: [Line] = decodeAssets("LinesPreview", from: Bundle.main),
              let tags: LinguisticTagOrder = decodeAsset("TagsPreview", from: Bundle.main) else {
            fatalError("Failed to decode assets")
        }
        return Ballad(lines: lines, tags: tags)
    }
    
    func body(content: Content, context: Ballad) -> some View {
        content
            .environment(context)
    }
}
