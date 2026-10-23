# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `WeightedSet.weightedRandomElement()` selects an element with a probability proportional to its weight, never selecting elements without a positive weight.

### Fixed

- `SoundBank` now gives each instrument its own sampler, mixed through the shared reverb. Previously all instruments shared one sampler, so the most recently loaded preset played every part, and stopping a note on one instrument stopped the same pitch on the others. `SoundBank.play(note:)`, `startNote(_:)` and `stopNote(_:)` now take the instrument to play on.

- `Composer` now chooses note duration and interval vectors in proportion to how often they occur in the tunes. It previously chose uniformly among the distinct vectors, ignoring their weights. Sets with no positively weighted vectors are now discarded.

- `Cycle.mostFrequent` now returns the element that occurs most often. It previously ignored the counts and returned the greatest element. Ties are resolved in favour of the greatest element.
- `Tune.mostFrequentNote` now counts notes by pitch alone, ignoring duration and velocity, and returns the first note in the tune with that pitch.
- As a result, `Composer.initialNote` is the most frequent pitch across the tunes rather than the highest, so compositions no longer begin at the ceiling of their range.
- `TuneTests.testMostFrequentNoteNumber` was missing its `@Test` attribute and never ran.
