//
//  StanzasView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 02/11/2023.
//

import SwiftUI

struct StanzasView: View {
    let stanzas: [Stanza]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(stanzas) { stanza in
                StanzaView(stanza: stanza)
                Spacer()
            }
        }
    }
}

#Preview("Unrecited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
	let canto = ballad.cantos[0]
	canto.isRecited = false
    return ScrollView {
		StanzasView(stanzas: ballad.cantos[0].stanzas)
    }
    .frame(width: 400.0)
}

#Preview("Recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
	let canto = ballad.cantos[0]
	canto.isRecited = true
    return ScrollView {
		StanzasView(stanzas: canto.stanzas)
    }
    .frame(width: 400.0)
}
