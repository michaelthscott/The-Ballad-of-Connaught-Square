//
//  RecitationSettingsView.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 11/11/2026.
//

import SwiftUI

/// The tunables of the recitation: how the pitch moves, how fast the voices speak, and how long they
/// pause. They're the performance's own, so a change is heard from its next part, and the app keeps
/// them between launches. Clicking a tunable's title resets it to the standard value.
///
/// It's made of sections, to go in a form beside the voices.
struct RecitationSettingsView: View {
	@Environment(Performance.self) var performance

	var body: some View {
		@Bindable var performance = performance
		let standard = DeclamationStyle.standard
		Section("Contour (semitones)") {
			slider("Rise to first stress", value: $performance.style.contourDepth, default: standard.contourDepth, in: 0...8)
			slider("Declination", value: $performance.style.declination, default: standard.declination, in: 0...6)
			slider("Final fall", value: $performance.style.finalFall, default: standard.finalFall, in: 0...8)
			slider("Question rise", value: $performance.style.finalRise, default: standard.finalRise, in: 0...8)
			slider("Stress boost", value: $performance.style.stressBoost, default: standard.stressBoost, in: 0...5)
		}
		Section("Rate (× default)") {
			slider("Base rate", value: $performance.style.baseRate, default: standard.baseRate, in: 0.4...1.6)
			slider("Stressed words", value: $performance.style.stressRate, default: standard.stressRate, in: 0.6...1.2)
		}
		Section("Pauses (ms)") {
			pause("Trailing …", $performance.style.trailingEllipsisPause, default: standard.trailingEllipsisPause)
			pause("Hesitation …", $performance.style.hesitationPause, default: standard.hesitationPause)
			pause("Comma", $performance.style.commaPause, default: standard.commaPause)
			pause("Line end", $performance.style.lineEndPause, default: standard.lineEndPause)
			pause("Caesura", $performance.style.caesuraPause, default: standard.caesuraPause)
		}
	}

	/// A tunable's title, which resets the tunable to its standard value when clicked.
	private func resetTitle(_ title: String, reset: @escaping () -> Void) -> some View {
		Button(title, action: reset)
			.buttonStyle(.plain)
			.help("Click to reset to the standard value")
	}

	private func slider<Value: BinaryFloatingPoint>(_ title: String, value: Binding<Value>, default standard: Value, in range: ClosedRange<Value>) -> some View
	where Value.Stride: BinaryFloatingPoint {
		LabeledContent {
			HStack {
				Slider(value: value, in: range)
				Text(Double(value.wrappedValue), format: .number.precision(.fractionLength(2)))
					.monospacedDigit()
					.frame(width: 44, alignment: .trailing)
			}
		} label: {
			resetTitle(title) { value.wrappedValue = standard }
		}
	}

	private func pause(_ title: String, _ duration: Binding<Duration>, default standard: Duration) -> some View {
		let milliseconds = Binding<Double> {
			Double(duration.wrappedValue.components.seconds) * 1000 + Double(duration.wrappedValue.components.attoseconds) / 1e15
		} set: {
			duration.wrappedValue = .milliseconds(Int($0.rounded()))
		}
		return LabeledContent {
			HStack {
				Slider(value: milliseconds, in: 0...1500, step: 25)
				Text(milliseconds.wrappedValue, format: .number.precision(.fractionLength(0)))
					.monospacedDigit()
					.frame(width: 44, alignment: .trailing)
			}
		} label: {
			resetTitle(title) { duration.wrappedValue = standard }
		}
	}
}

#Preview("RecitationSettingsView", traits: .modifier(PreviewPerformance())) {
	Form {
		RecitationSettingsView()
	}
	.formStyle(.grouped)
}
