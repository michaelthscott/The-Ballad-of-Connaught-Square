# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Removed

- The `Duration.seconds` extension, which only its tests used. It was easily confused with the static `Duration.seconds(_:)`.

- `Note.off`, the note's release velocity, and the `off:` parameter of `Note.init`. It was generated for every note but never used, as `AVAudioUnitSampler.stopNote` takes no velocity.

- The `Recitable` protocol, which nothing used. Its `isRecited` setter changed copies of the elements rather than the elements themselves.

### Changed

- `decodeAsset` now throws, so a missing or malformed asset reports why it failed rather than returning `nil`. `decodeAssets` has been removed; to decode an array, ask `decodeAsset` for an array type.

- `Speakers.nextSpeaker` is now the `takeTurn()` method, as reading it passed the turn to the other speaker.

- `Speaker` is now a struct rather than a class, and `Speakers.availableSpeakers` is a constant.

- `Tune` is now a `Sendable` struct rather than a class, so the built-in tunes no longer need `nonisolated(unsafe)`.

- `NoteVelocity.gaussianRandom()` no longer creates a GameplayKit random source and distribution for every note. It now samples a normal distribution of the same shape directly from Swift's random number generator, and has a `gaussianRandom(using:)` variant that takes a generator. `NoteVelocity` no longer imports GameplayKit.

- Each instrument's part now opens on the pitch of `Composer.initialNote`, so all the instruments begin in unison on the tunes' most frequent pitch. Previously the starting note was only the point the first interval was measured from, and was rarely heard.

- `Composer` works out `initialNote`, `ceilingNote` and `floorNote` once when it's created, rather than for every note it composes. A composer whose tunes give an invalid range now fails when it's created rather than when it first composes.

- Each part after the first in a line now follows a second after the part before it. The second of silence previously ran alongside the speech, so there was no audible gap, and the last part of a line had none at all. Silences in a batch before any music now finish before the part is spoken; music, and the silence after it, still plays under the speech.

- The performance's events and the notes each instrument played are now logged with `Logger` at the debug level rather than printed. A failure to restart the audio engine on resume is logged as an error rather than ignored.

- The legal syllable onsets are built once rather than every time a word is split into syllables.

- `LinguisticTag.allCases` is now the synthesized, constant list of cases rather than a mutable `nonisolated(unsafe)` variable.

### Added

- The performance can be paused and resumed. `Performance` has a `state` of `.stopped`, `.playing` or `.paused`, replacing `isFinished`, and `play()`, `pause()`, `resume()` and `stop()` methods. Pausing holds the voice at the next word and holds any sounding notes, which play out the rest of their length on resume.

- `PauseGate`, which tasks wait at while it's paused, and whose `sleep(for:)` doesn't count time spent paused. Notes and the silences between parts are timed with the sound bank's gate.

- `PerformanceView` has a play/pause button and a stop button, which is disabled when the performance is stopped.

- `WeightedSet.weightedRandomElement()` selects an element with a probability proportional to its weight, never selecting elements without a positive weight.

### Fixed

- `String.words` no longer counts the empty strings between repeated spaces, or an empty string, as words, and now also separates words at newlines and tabs. An empty part's estimated speaking time is now zero.

- A task waiting at a paused `PauseGate` now returns as soon as it's cancelled, rather than staying suspended until the gate is resumed. Pausing and resuming also read the clock under the gate's lock, so racing calls can no longer record a pause of negative length.

- The performance button always showed the play icon, as the title and image it updated were never displayed.

- Performing again after stopping now starts with no parts shown as recited.

- Lines are now sorted consistently by their linguistic tags. The comparison let two lines each come before the other, so the order was unreliable. The first position where two lines' tags differ now decides the order, so the ballad opens with lines led by the most frequent tag.

- Vowels with no consonant between them, as in "being", are now separate syllables. Previously the second vowel replaced the first, so the syllable and its stress were lost.

- Single, double and dactylic rhymes now compare the words from the stressed vowel to the end. They previously compared only the stressed syllable, including its leading consonants, so "bell" and "tell" didn't rhyme, while "almost" and "also" counted as a double rhyme.

- Encoding a `Part` now keeps its pronunciations. They were read back from an attributed string attribute that was never set, so none were encoded.

- `Part.attributedString` now applies each pronunciation at its location. It searched for the text instead, so a word appearing more than once in a part got the pronunciation on its first occurrence. A pronunciation outside the string is now ignored, where previously it crashed or emptied the whole string.

- Every stanza is now in a canto. A stanza starting with a tag missing from the ballad's tag order was left out, so a ballad made without a tag order had no cantos at all. Stanzas like these now follow in cantos of their own, and stanzas with no tags join the other words.

- `Lexicon.wordsWith(syllable:)` now keeps the largest groups first, as intended. A final sort put all the words in alphabetical order.

- A performance that finished just after being stopped and restarted could mark the new performance as finished.

- Stopping and quickly restarting the performance could cut its first line short, as the stopped line's cancellation ended the new line's wait. The stopped performance was also left waiting forever for its last line to finish.

- Performing again after stopping now always starts with the second speaker. The speakers' turns previously carried on from the last performance, so it could start with the first speaker. `Speakers` has a `resetTurns()` method, which `Performance.play()` calls.

- The performance now stops once it has recited every part. It previously started the ballad over and never finished. `BalladCursorSequence` stays finished after the last part, when its `cursor` and `currentPart`, now optional, are `nil`, and `EventsSequence.next()` returns `nil`.

- A ballad with no parts no longer crashes `BalladCursorSequence`, and a performance of it stops straight away. Cantos, stanzas and lines without any parts are skipped.

- The app no longer crashes at launch when no British English voice is installed. `Speakers` falls back to the default voice for the user's language.

- Pausing just as the accompaniment began could leave it sounding while paused. An instrument that started playing after the pause restarted the paused engine, so held notes became audible again. `SoundBank.startEngine()` now does nothing while the engine is paused; only `resumeEngine()` restarts it. `SoundBank` has an `isEngineRunning` property.

- Stopping and quickly restarting the performance could silence its opening music. The stopped performance's engine stop could take effect after the new performance had started the engine. A performance now waits for any earlier change to the engine before it begins.

- A performance stopped just before a part was due to be spoken no longer speaks it. `SpeechSynthesizer.speak(_:in:)` returns straight away if its task is already cancelled.

- Speakers are ordered by name and then by identifier, so different voices with the same name have a consistent order. They were previously neither equal nor ordered.

- `NoteVelocity.random(using:)` now uses the generator it's given. It previously ignored it.

- `LinguisticTagOrder.index(of:)` no longer adds a tag the ordering doesn't hold. It now returns `nil` for such a tag. `areOrdered(_:_:)` places tags missing from the ordering after all the others, as before.

- Looking an element up in a `WeightedSet` no longer changes the set. `weight(of:)`, `contains(_:)` and the set operations that use them previously added a zero-weight entry for any element the set didn't hold. A new `existingPosition(of:)` returns `nil` instead. `position(of:)` still adds an entry when needed, for use when assigning a weight. `Line.countFor(tag:)` and `LinguisticTagOrder.weight(of:)` now use `weight(of:)`.
- `WeightedSet.subtracting(_:)` no longer changes the set it's called on. Because `WeightedSet` is a class, its "copy" was the same set.

- `Vector` now hashes its elements alone, consistent with its equality, which ignores weight. Its synthesized hash previously included the weight, so equal vectors with different weights could hash differently and be duplicated in a `Set` or `Dictionary`.

- `Vector`'s `<` is now a strict ordering. Vectors of the same length previously compared as less if any element was less, so `[1, 2] < [2, 1]` and `[2, 1] < [1, 2]` were both true. This made sorting unreliable and could make equal `WeightedSet`s compare as unequal or hash differently. Shorter vectors still come first; vectors of the same length are now compared element by element.

- `MIDIEvent.on` and `MIDIEvent.off` had their status bytes swapped. Note On is now `0x90` and Note Off `0x80`.

- `Composer.floorNote` is now the lowest note across all the tunes, matching `ceilingNote`, which is the highest. It previously took the highest of the tunes' lowest notes, narrowing the range when the tunes' lowest notes differ.

- `SoundBank` now gives each instrument its own sampler, mixed through the shared reverb. Previously all instruments shared one sampler, so the most recently loaded preset played every part, and stopping a note on one instrument stopped the same pitch on the others. `SoundBank.play(note:)`, `startNote(_:)` and `stopNote(_:)` now take the instrument to play on.

- `Composer` now chooses note duration and interval vectors in proportion to how often they occur in the tunes. It previously chose uniformly among the distinct vectors, ignoring their weights. Sets with no positively weighted vectors are now discarded.

- `Cycle.mostFrequent` now returns the element that occurs most often. It previously ignored the counts and returned the greatest element. Ties are resolved in favour of the greatest element.
- `Tune.mostFrequentNote` now counts notes by pitch alone, ignoring duration and velocity, and returns the first note in the tune with that pitch.
- As a result, `Composer.initialNote` is the most frequent pitch across the tunes rather than the highest, so compositions no longer begin at the ceiling of their range.
- `TuneTests.testMostFrequentNoteNumber` was missing its `@Test` attribute and never ran.
