//
//  StanzaView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 30/11/2023.
//

import SwiftUI

struct StanzaView: View {
    let stanza: Stanza
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(stanza.recitedLines) { line in
                LineView(line: line)
            }
        }
    }
}

#Preview("Unrecited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
	let stanza = ballad.cantos[0].stanzas[0]
	stanza.isRecited = false
	return ScrollView {
		StanzaView(stanza: stanza)
	}
	.frame(width: 400.0)
}

#Preview("Recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
	let stanza = ballad.cantos[0].stanzas[0]
	stanza.isRecited = true
    return ScrollView {
        StanzaView(stanza: stanza)
    }
    .frame(width: 400.0)
}
