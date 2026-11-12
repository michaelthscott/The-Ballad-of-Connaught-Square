//
//  VoiceDownloadNotice.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 11/11/2026.
//

import SwiftUI

/// Asks for the preferred voices to be downloaded while any aren't installed, saying where.
/// Apps can't download voices themselves, so the listener has to, in the system's settings.
struct VoiceDownloadNotice: View {
    @Environment(Speakers.self) var speakers

    /// Where the voices are downloaded on this platform.
    private static var whereToDownload: String {
        #if os(macOS)
        "System Settings → Accessibility → Read & Speak → System voice → Manage Voices… → English (United Kingdom)"
        #else
        "Settings → Accessibility → Read & Speak → Voices → English → English (UK)"
        #endif
    }

    var body: some View {
        if !speakers.missingVoiceNames.isEmpty {
            let voices = speakers.missingVoiceNames.map { "\($0) (Enhanced)" }.formatted(.list(type: .and))
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The ballad is best recited by \(voices). Download them in \(Self.whereToDownload).")
                    Text("Until then, other voices stand in.")
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "arrow.down.circle")
            }
            .font(.callout)
        }
    }
}

#Preview("VoiceDownloadNotice", traits: .modifier(PreviewSpeakers())) {
    VoiceDownloadNotice()
        .padding()
}
