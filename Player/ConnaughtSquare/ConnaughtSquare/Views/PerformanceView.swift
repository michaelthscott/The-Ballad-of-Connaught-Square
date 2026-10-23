//
//  PerformanceView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 28/03/2025.
//

import SwiftUI

struct PerformanceView: View {
    @Environment(Ballad.self) var ballad
    @Environment(Speakers.self) var speakers
    @Environment(Performance.self) var performance

    @Namespace private var scrollPosition

    var body: some View {
        VStack {
            Text(ballad.title)
                .font(.title)
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    HStack(alignment: .top) {
                        CantosView(cantos: ballad.recitedCantos)
                            .id(scrollPosition)
                        Spacer()
                    }
                }
                .frame(width: 350.0)
                .onChange(of: performance.spokenPartCount) {
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
    PerformanceView()
}
