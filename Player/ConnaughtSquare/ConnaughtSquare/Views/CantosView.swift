//
//  CantosView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 02/11/2023.
//

import SwiftUI

struct CantosView: View {
	@Environment(Ballad.self) var ballad
	let cantos: [Canto]
	
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(cantos) { canto in
				CantoView(canto: canto)
				Spacer()
            }
		}
    }
}

#Preview("Ballad unrecited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
    ballad.isRecited = false
	return ScrollView {
		CantosView(cantos: ballad.cantos)
	}
	.frame(width: 400.0)
}

#Preview("First line part recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
    ballad.isRecited = false
    ballad.cantos.first?.stanzas.first?.lines.first?.parts.first?.isRecited = true
	return ScrollView {
		CantosView(cantos: ballad.cantos)
	}
	.frame(width: 400.0)
}

#Preview("First line recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
    ballad.isRecited = false
    ballad.cantos.first?.stanzas.first?.lines.first?.isRecited = true
	return ScrollView {
		CantosView(cantos: ballad.cantos)
	}
	.frame(width: 400.0)
}

#Preview("First stanza recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
    ballad.isRecited = false
    ballad.cantos.first?.stanzas.first?.isRecited = true
	return ScrollView {
		CantosView(cantos: ballad.cantos)
	}
	.frame(width: 400.0)
}

#Preview("First canto recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
    ballad.isRecited = false
    ballad.cantos.first?.isRecited = true
	return ScrollView {
		CantosView(cantos: ballad.cantos)
	}
	.frame(width: 400.0)
}

#Preview("Ballad recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
    ballad.isRecited = true
	return ScrollView {
		CantosView(cantos: ballad.cantos)
    }
	.frame(width: 400.0)
}
