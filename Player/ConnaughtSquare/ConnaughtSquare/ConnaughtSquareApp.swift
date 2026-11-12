//
//  ConnaughtSquareApp.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 22/07/2026.
//

import SwiftUI
import AVFoundation

/// Where the music's volume is kept between launches.
private let musicVolumeKey = "MusicVolume"

@main
struct ConnaughtSquareApp: App {
    @State private var performance = Performance()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // The recitation, the roles' volumes and the music's volume are tuned in the settings, and
        // kept between launches. The app loads and saves them, rather than the performance, so that
        // performances made in tests leave them alone.
        let performance = Performance()
        performance.style = .saved()
        performance.speakers.volumes = Speakers.savedVolumes()
        if let musicVolume = UserDefaults.standard.object(forKey: musicVolumeKey) as? NSNumber {
            performance.musicVolume = min(max(musicVolume.floatValue, 0), 1)
        }
        _performance = State(initialValue: performance)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(performance.ballad)
                .environment(performance.speakers)
                .environment(performance)
                // A voice downloaded while the app is open is taken up, so the listener needn't relaunch it.
                .task {
                    for await _ in NotificationCenter.default.notifications(named: AVSpeechSynthesizer.availableVoicesDidChangeNotification) {
                        performance.speakers.refresh()
                    }
                }
                // The voices may have been downloaded in the system's settings while the app was in the background.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        performance.speakers.refresh()
                    }
                }
                .modifier(SavesSettings(performance: performance))
        }
        #if os(macOS)
        Settings {
            SettingsWindow()
                .environment(performance.ballad)
                .environment(performance.speakers)
                .environment(performance)
                // The settings can be open with the main window closed.
                .modifier(SavesSettings(performance: performance))
        }
        #endif
    }
}

/// Saves the settings tuned in the app as they change, for the next launch.
private struct SavesSettings: ViewModifier {
    let performance: Performance

    func body(content: Content) -> some View {
        content
            .onChange(of: performance.style) { _, style in
                style.save()
            }
            .onChange(of: performance.speakers.volumes) {
                performance.speakers.saveVolumes()
            }
            .onChange(of: performance.musicVolume) { _, volume in
                UserDefaults.standard.set(volume, forKey: musicVolumeKey)
            }
    }
}
