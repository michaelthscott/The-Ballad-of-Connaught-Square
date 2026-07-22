//
//  PerformanceView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 28/03/2025.
//

import SwiftUI

struct PerformanceView: View {
    static private let buttonTitles = (start: "Perform Ballad", stop: "Stop Performance")
    static private let buttonImageNames = (start: "play", stop: "stop")
    @Environment(Ballad.self) var ballad
    @Environment(Speakers.self) var speakers
    @Environment(Performance.self) var performance

    @Namespace private var scrollPosition
    @State private var buttonTitle = Self.buttonTitles.start
    @State private var buttonImageName = Self.buttonImageNames.start
    @State private var isPerforming: Bool = false
    
    private func buttonAction() {
        if !isPerforming {
            performance.perform()
            buttonTitle = Self.buttonTitles.stop
            buttonImageName = Self.buttonImageNames.stop
            isPerforming = true
        } else {
            performance.stop()
            buttonTitle = Self.buttonTitles.start
            buttonImageName = Self.buttonImageNames.start
            isPerforming = false
        }
    }
    
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
            Button("Perform", systemImage: "play", action: buttonAction)
                .labelStyle(.iconOnly)
                .onChange(of: performance.isFinished) { oldValue, newValue in
                    if oldValue == false, newValue == true {
                        buttonTitle = Self.buttonTitles.start
                        buttonImageName = Self.buttonImageNames.start
                        isPerforming = false
                    }
                }
        }
        .onDisappear() {
            performance.stop()
            buttonTitle = Self.buttonTitles.start
            buttonImageName = Self.buttonImageNames.start
            isPerforming = false
        }
        .padding()
    }
}

#Preview("Performance", traits: .modifier(PreviewBallad()), .modifier(PreviewSpeakers()), .modifier(PreviewPerformance())) {
    PerformanceView()
}
