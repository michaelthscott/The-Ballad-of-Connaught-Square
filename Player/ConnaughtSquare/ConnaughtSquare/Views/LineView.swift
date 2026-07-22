//
//  LineView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 30/11/2023.
//

import SwiftUI

struct LineView: View {
    let line: Line
    
    var body: some View {
		HStack(alignment: .top) {
			Text(line.recitedParts.map({ $0.quotedString }).joined(separator: " "))
		}
    }
}

#Preview("Unrecited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
	let line = ballad.lines.filter { line in
		line.numberOfParts == 3
	}.first!
	line.isRecited = false
	return LineView(line: line)
		.frame(width: 400.0)
}

#Preview("One part recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
	let line = ballad.lines.filter { line in
		line.numberOfParts == 3
	}.first!
	line.parts[0].isRecited = true
	return LineView(line: line)
		.frame(width: 400.0)
}

#Preview("Two parts recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
	let line = ballad.lines.filter { line in
		line.numberOfParts == 3
	}.first!
	line.parts[0].isRecited = true
	line.parts[1].isRecited = true
	return LineView(line: line)
		.frame(width: 400.0)
}

#Preview("Recited", traits: .modifier(PreviewBallad())) {
    @Previewable @Environment(Ballad.self) var ballad
    let line = ballad.lines.filter { line in
        line.numberOfParts == 3
    }.first!
	line.isRecited = true
    return LineView(line: line)
		.frame(width: 400.0)
}
