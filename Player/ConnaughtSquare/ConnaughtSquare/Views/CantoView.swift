//
//  CantoView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 07/12/2023.
//

import SwiftUI

struct CantoView: View {
    let canto: Canto
    /// Whether the title is shown before any of the canto has been recited.
    var showsTitle = false

    var body: some View {
        VStack(alignment: .leading) {
            if showsTitle || canto.isRecited {
                Text(canto.title).bold()
            } else {
                Text(canto.title).bold().hidden()
            }
            Spacer()
            StanzasView(stanzas: canto.recitedStanzas)
        }
    }
}

#Preview("Unrecited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
    ScrollView {
		CantoView(canto: ballad.cantos[0])
    }
    .frame(width: 400.0)
}

#Preview("Recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
    let canto = ballad.cantos[0]
	canto.isRecited = true
    return ScrollView {
		CantoView(canto: canto)
    }
	.frame(width: 400.0)
}
