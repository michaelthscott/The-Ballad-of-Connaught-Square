//
//  VersionView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 11/11/2026.
//

import SwiftUI

extension Bundle {
	/// The version and build number, such as "1.3.2 (7)", read from the Info.plist.
	var versionAndBuild: String {
		let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
		let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
		return "\(version) (\(build))"
	}
}

/// The app's version and build number, shown in the settings on every platform.
struct VersionView: View {
	var body: some View {
		LabeledContent("Version", value: Bundle.main.versionAndBuild)
	}
}

#Preview("VersionView") {
	VersionView()
}
