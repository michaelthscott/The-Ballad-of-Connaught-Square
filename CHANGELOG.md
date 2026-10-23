# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `WeightedSet.weightedRandomElement()` selects an element with a probability proportional to its weight, never selecting elements without a positive weight.

### Fixed

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
