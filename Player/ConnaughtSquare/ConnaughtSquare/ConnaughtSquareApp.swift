//
//  ConnaughtSquareApp.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 22/07/2026.
//

import SwiftUI

@main
struct ConnaughtSquareApp: App {
    @State private var performance = Performance()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(performance.ballad)
                .environment(performance.speakers)
                .environment(performance)
        }
    }
}
