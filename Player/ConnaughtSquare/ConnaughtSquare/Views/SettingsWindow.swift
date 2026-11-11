//
//  SettingsWindow.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 10/11/2026.
//

#if os(macOS)
import SwiftUI

/// The macOS Settings window, opened from the app menu or with ⌘,; on iOS the settings are a tab of their own.
struct SettingsWindow: View {
	/// The panes listed in the sidebar.
	enum Pane: String, CaseIterable, Identifiable {
		case voices = "Voices"
		case tagOrder = "Tag Order"

		var id: Self { self }

		var systemImage: String {
			switch self {
			case .voices: "person.wave.2"
			case .tagOrder: "list.number"
			}
		}
	}

	@State private var selectedPane: Pane? = .voices

	var body: some View {
		NavigationSplitView {
			List(Pane.allCases, selection: $selectedPane) { pane in
				Label(pane.rawValue, systemImage: pane.systemImage)
			}
			.safeAreaInset(edge: .bottom) {
				VersionView()
					.font(.caption)
					.foregroundStyle(.secondary)
					.padding()
			}
			.navigationSplitViewColumnWidth(170)
			.toolbar(removing: .sidebarToggle)
		} detail: {
			Group {
				switch selectedPane {
				case .voices:
					Form {
						SpeakersView()
					}
				case .tagOrder:
					VStack {
						TagOrderView()
						TagListView()
					}
					.padding()
				case nil:
					EmptyView()
				}
			}
			.navigationTitle(selectedPane?.rawValue ?? "Settings")
		}
		.frame(width: 650, height: 500)
	}
}

#Preview("SettingsWindow", traits: .modifier(PreviewBallad()), .modifier(PreviewSpeakers())) {
	SettingsWindow()
}
#endif
