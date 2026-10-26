//
//  ConnaughtSquareApp.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 22/07/2026.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct ConnaughtSquareApp: App {
    @State private var performance = Performance()
    /// The error when the tagger's tag scheme is unavailable, which asks whether to request its assets.
    @State private var unavailableError: LinguisticTaggerError?
    @State private var isUnavailableAlertPresented = false
    /// The error when the request for the tagger's assets fails, after which the app can't continue.
    @State private var requestError: (any Error)?
    @State private var isRequestFailedAlertPresented = false
    /// Whether the app can't continue without the tagger. On iOS and visionOS the user quits the app themselves.
    @State private var isTaggingUnavailable = false

    #if os(macOS)
    private let quitButtonTitle = "Quit"
    private let quitMessage = "The app will now quit."
    #else
    private let quitButtonTitle = "OK"
    private let quitMessage = "Please quit the app."
    #endif

    var body: some Scene {
        WindowGroup {
            Group {
                if isTaggingUnavailable {
                    ContentUnavailableView("Linguistic Tagging Unavailable", systemImage: "text.magnifyingglass", description: Text("The ballad can't be sorted without linguistic tagging. \(quitMessage)"))
                } else {
                    ContentView()
                        .environment(performance.ballad)
                        .environment(performance.speakers)
                        .environment(performance)
                }
            }
            .task {
                checkTagSchemeAvailability()
            }
            .alert("Linguistic Tagging Unavailable", isPresented: $isUnavailableAlertPresented, presenting: unavailableError) { _ in
                Button("Request Assets") {
                    Task {
                        await requestAssets()
                    }
                }
                Button(quitButtonTitle, role: .cancel) {
                    quit()
                }
            } message: { error in
                Text("\(error.localizedDescription) The ballad is sorted by its linguistic tags. Do you want to request the assets?")
            }
            .alert("Couldn't Load the Assets", isPresented: $isRequestFailedAlertPresented) {
                Button(quitButtonTitle, role: .cancel) {
                    quit()
                }
            } message: {
                Text("\(requestError?.localizedDescription ?? "The request failed.") \(quitMessage)")
            }
        }
    }

    /// Checks that the tagger's tag scheme is available, asking whether to request its assets when it isn't.
    private func checkTagSchemeAvailability() {
        do {
            try LinguisticTagger().checkTagSchemeAvailability()
        } catch {
            unavailableError = error
            isUnavailableAlertPresented = true
        }
    }

    /// Requests the tagger's assets, informing the user before quitting when the request fails.
    private func requestAssets() async {
        do {
            try await LinguisticTagger().requestAssets()
        } catch {
            requestError = error
            isRequestFailedAlertPresented = true
        }
    }

    /// Quits the app on macOS, as it can't sort the ballad without the tagger.
    /// iOS and visionOS apps don't quit themselves, so there the user is left to quit the app.
    private func quit() {
        #if os(macOS)
        NSApplication.shared.terminate(nil)
        #else
        isTaggingUnavailable = true
        #endif
    }
}
