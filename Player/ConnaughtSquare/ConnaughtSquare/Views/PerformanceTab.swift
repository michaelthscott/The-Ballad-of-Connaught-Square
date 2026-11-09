//
//  PerformanceTab.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 28/03/2025.
//

import SwiftUI

struct PerformanceTab: View {
    @Environment(Ballad.self) var ballad
    @Environment(Speakers.self) var speakers
    @Environment(Performance.self) var performance

    @Namespace private var scrollPosition

    var body: some View {
        VStack {
            // Hidden rather than left out until it's announced, so the layout doesn't move when it appears.
            Text(ballad.title)
                .font(.title)
                .opacity(performance.isTitleAnnounced ? 1 : 0)
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    HStack(alignment: .top) {
                        CantosView(cantos: Array(ballad.cantos.prefix(performance.announcedCantoCount)), showsTitles: true)
                            .id(scrollPosition)
                        Spacer()
                    }
                }
                .frame(width: 350.0)
                .onChange(of: performance.spokenPartCount) {
                     proxy.scrollTo(scrollPosition, anchor: .bottom)
                }
                .onChange(of: performance.announcedCantoCount) {
                     proxy.scrollTo(scrollPosition, anchor: .bottom)
                }
            }
            HStack {
                if performance.state == .playing {
                    Button("Pause Performance", systemImage: "pause.fill") {
                        performance.pause()
                    }
                } else {
                    Button(performance.state == .paused ? "Resume Performance" : "Perform Ballad", systemImage: "play.fill") {
                        performance.play()
                    }
                }
                Button("Stop Performance", systemImage: "stop.fill") {
                    performance.stop()
                }
                .disabled(performance.state == .stopped)
            }
            .labelStyle(.iconOnly)
        }
        .onDisappear() {
            performance.stop()
        }
        .padding()
    }
}

#Preview("Performance", traits: .modifier(PreviewBallad()), .modifier(PreviewSpeakers()), .modifier(PreviewPerformance())) {
    PerformanceTab()
}
