//
//  Tune.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 05/12/2023.
//

// TODO: The notes of a tune should be cyclic.
// https://github.com/apple/swift-algorithms/blob/1.2.0/Sources/Algorithms/Cycle.swift#L13

typealias NoteDurationVector = Vector<NoteDuration>
typealias NoteIntervalVector = Vector<NoteInterval>
typealias NoteDurationVectors = WeightedSet<NoteDurationVector>
typealias NoteIntervalVectors = WeightedSet<NoteIntervalVector>

/// A tune.
final class Tune {
    nonisolated(unsafe) static let theSashMyFatherWore = Tune("The Sash My Father Wore",
										  [Note(value: .d3, duration: .quaver),
                                          Note(value: .c3, duration: .quaver),
                                          Note(value: .b2, duration: .crotchet),
                                          Note(value: .d2, duration: .crotchet),
                                          Note(value: .g2, duration: .crotchet),
                                          Note(value: .a2, duration: .crotchet),
                                          Note(value: .b2, duration: .dottedCrotchet),
                                          Note(value: .a2, duration: .quaver),
                                          Note(value: .g2, duration: .crotchet),
                                          Note(value: .b2, duration: .quaver),
                                          Note(value: .c3, duration: .quaver),
                                          Note(value: .d3, duration: .crotchet),
                                          Note(value: .d3, duration: .crotchet),
                                          Note(value: .c3, duration: .quaver),
                                          Note(value: .b2, duration: .quaver),
                                          Note(value: .c3, duration: .crotchet),
                                          Note(value: .a2, duration: .dottedMinim),
                                          Note(value: .a2, duration: .crotchet),
                                          Note(value: .a2, duration: .crotchet),
                                          Note(value: .fSharp2, duration: .crotchet),
                                          Note(value: .d2, duration: .crotchet),
                                          Note(value: .fSharp2, duration: .crotchet),
                                          Note(value: .a2, duration: .dottedCrotchet),
                                          Note(value: .b2, duration: .quaver),
                                          Note(value: .c3, duration: .quaver),
                                          Note(value: .b2, duration: .quaver),
                                          Note(value: .a2, duration: .quaver),
                                          Note(value: .d3, duration: .crotchet),
                                          Note(value: .d3, duration: .crotchet),
                                          Note(value: .c3, duration: .quaver),
                                          Note(value: .b2, duration: .quaver),
                                          Note(value: .a2, duration: .crotchet),
                                          Note(value: .g2, duration: .dottedMinim)])
    
    nonisolated(unsafe) static let theBritishGrenadiers = Tune("The British Grenadiers",
										   [Note(value: .d2, duration: .crotchet),
                                           Note(value: .g2, duration: .crotchet),
                                           Note(value: .d2, duration: .crotchet),
                                           Note(value: .g2, duration: .crotchet),
                                           Note(value: .a2, duration: .crotchet),
                                           Note(value: .b2, duration: .minim),
                                           Note(value: .a2, duration: .crotchet),
                                           Note(value: .b2, duration: .quaver),
                                           Note(value: .c3, duration: .quaver),
                                           Note(value: .d3, duration: .crotchet),
                                           Note(value: .g2, duration: .crotchet),
                                           Note(value: .b2, duration: .quaver),
                                           Note(value: .a2, duration: .quaver),
                                           Note(value: .g2, duration: .quaver),
                                           Note(value: .fSharp2, duration: .quaver),
                                           Note(value: .g2, duration: .dottedMinim),
                                           Note(value: .e3, duration: .quaver),
                                           Note(value: .e3, duration: .quaver),
                                           Note(value: .d3, duration: .dottedCrotchet),
                                           Note(value: .e3, duration: .quaver),
                                           Note(value: .d3, duration: .crotchet),
                                           Note(value: .c3, duration: .crotchet),
                                           Note(value: .b2, duration: .dottedCrotchet),
                                           Note(value: .c3, duration: .quaver),
                                           Note(value: .d3, duration: .crotchet),
                                           Note(value: .d3, duration: .crotchet),
                                           Note(value: .e3, duration: .crotchet),
                                           Note(value: .e3, duration: .crotchet),
                                           Note(value: .d3, duration: .quaver),
                                           Note(value: .c3, duration: .quaver),
                                           Note(value: .b2, duration: .quaver),
                                           Note(value: .a2, duration: .quaver),
                                           Note(value: .g2, duration: .minim),
                                           Note(value: .fSharp2, duration: .crotchet),
                                           Note(value: .d2, duration: .quaver),
                                           Note(value: .d2, duration: .quaver),
                                           Note(value: .g2, duration: .crotchet),
                                           Note(value: .d2, duration: .crotchet),
                                           Note(value: .g2, duration: .crotchet),
                                           Note(value: .a2, duration: .crotchet),
                                           Note(value: .b2, duration: .minim),
                                           Note(value: .a2, duration: .crotchet),
                                           Note(value: .b2, duration: .quaver),
                                           Note(value: .c3, duration: .quaver),
                                           Note(value: .d3, duration: .crotchet),
                                           Note(value: .g2, duration: .crotchet),
                                           Note(value: .b2, duration: .quaver),
                                           Note(value: .a2, duration: .quaver),
                                           Note(value: .g2, duration: .quaver),
                                           Note(value: .fSharp2, duration: .quaver),
                                           Note(value: .g2, duration: .dottedMinim)])
    
    static func randomTune(title: String, length: Int) -> Tune {
        let count = length > 0 ? length : 1
        var notes: [Note] = []
        for _ in 0..<count {
            notes.append(Note.randomNote())
        }
        return Tune(title, Cycle<Note>(elements: notes))
    }

	let title: String
	var notes: Cycle<Note>

    init(_ title: String, _ notes: Cycle<Note>) {
		self.title = title
		self.notes = notes
    }
    
    /// The total duration of the tune in microseconds.
    /// - Returns: The duration.
	var totalDuration: Duration {
		return .microseconds(notes.reduce(0) { $0 + $1.duration.rawValue })
    }
    
    /// The highest note in the tune.
    /// - Returns: The note.
	var highestNote: Note {
        notes.max()
    }
    
    /// The lowest note in the tune.
    /// - Returns: The note.
	var lowestNote: Note {
        notes.min()
    }

    /// The most frequently used note in the tune.
    /// - Returns: The note.
	var mostFrequentNote: Note {
		notes.mostFrequent
    }
    
	/// The  intervals between the notes used in the tune.
	/// - Parameter width: The width of the vectors.
	/// - Returns: A weighted set of interval vectors.
   func noteIntervalVectors(width: UInt = 2) -> NoteIntervalVectors {
		var vectors: [NoteIntervalVector] = []
		let notesSlices = notes.slices(width: width + 1)
		for notesSlice in notesSlices {
			var elements: [NoteInterval] = []
			let notePairsWindow = notesSlice.slices(width: 2)
			for notePair in notePairsWindow {
				let note1 = notePair[notePair.startIndex]
				let note2 = notePair[notePair.index(after: notePair.startIndex)]
				elements.append(NoteInterval(from: note1, to: note2))
			}
			vectors.append(Vector(elements, weight: 1))
		}
		return NoteIntervalVectors(vectors)
	}

	/// The note durations used in the tune.
	/// - Parameter width: The width of the vectors.
	/// - Returns: A weighted set of duration vectors.
	func noteDurationVectors(width: UInt = 2) -> NoteDurationVectors {
		var vectors: [NoteDurationVector] = []
		let slices = notes.slices(width: width)
		for slice in slices {
			var elements: [NoteDuration] = []
			for note in slice {
				elements.append(note.duration)
			}
			vectors.append(Vector(elements, weight: 1))
		}
		return NoteDurationVectors(vectors)
	}
    
}
