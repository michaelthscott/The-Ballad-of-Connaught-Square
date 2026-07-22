//
//  TagOrderView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 21/10/2023.
//

import SwiftUI

struct TagOrderView: View {
	@Environment(Ballad.self) var ballad
    @State var selectedOrder: TagSortOrder = .choose
	
    var body: some View {
        VStack {
			Picker(selection: $selectedOrder, label: Text("Tag Order")) {
				ForEach(TagSortOrder.allCases) { order in
					Text(order.rawValue).tag(order)
				}
			}
			.onChange(of: selectedOrder, initial: false) { oldValue, newValue in
				ballad.tags.orderTags(with: selectedOrder)
				ballad.sortLines()
				ballad.isRecited = false
			}
        }
    }

}

#Preview("", traits: .modifier(PreviewBallad())) {
    TagOrderView()
}
