//
//  TagListView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 04/01/2024.
//

import SwiftUI

// FIXME: This is slow on iOS. Maybe we can simplify the ordering as an array and save the change back after an item has been moved.

struct TagListView: View {
	@Environment(Ballad.self) var ballad
	
	var body: some View {
		VStack {
			List {
				ForEach(ballad.tags.ordering) { tag in
					HStack {
						Text(tag.name)
						Spacer()
						Text(String(tag.weight))
					}
				}
				.onMove { source, destination in
					ballad.tags.move(fromOffsets: source, toOffset: destination)
				}
			}
			.onChange(of: ballad.tags.description) {
				ballad.sortLines()
				ballad.isRecited = false
			}
			.listStyle(.automatic)
		}
	}
}

#Preview("TagListView", traits: .modifier(PreviewBallad())) {
    TagListView()
}
