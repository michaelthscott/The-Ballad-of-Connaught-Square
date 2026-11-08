# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.1] - 2026-11-08

### Added

- `scripts/testflight` archives the released version for iOS and macOS and uploads it to TestFlight, so it can be installed on iPhone, iPad and Mac. `scripts/release` runs it after tagging, unless `--skip-upload` is given. The app now declares that it uses no non-exempt encryption, so uploads skip the export compliance question, and that its category is Music, which the Mac App Store requires.

### Changed

- The app's name under its icon is now "Connaught Square" rather than "ConnaughtSquare".

- The app icon is now an Icon Composer icon, `AppIcon.icon`, in place of the `AppIcon` image set in the asset catalog. It uses the same artwork, so the system can render it in the light, dark, tinted and clear appearances.

## [1.0] - 2026-11-08

### Added

- The score can describe what each entry does with lines written as quotes, such as `> Plays before the ballad.`, which go anywhere and are otherwise skipped. In the Score asset, each division now says when it plays.

- The score can rest after each canto's title appears, before its first stanza's music comes in, with a `### Title` under `## Canto` that lists only rests, such as `- Rest: 0s–2s`. It can be left out, for no rest. `Score.cantoTitleRest` holds the seconds, and a `Cue` that begins a canto has its `cantoTitleRest`. In the Score asset, each canto's title is followed by 2s of rest.

- The ballad's title now appears as the performance starts, rather than being shown throughout, and the score can rest after it, before the introduction, with a `### Title` under `## Ballad` that lists only rests, such as `- Rest: 0s–2s`. It can be left out, for no rest. `Score.balladTitleRest` holds the seconds, a `Cue` that begins the ballad has `beginsBallad` and its `balladTitleRest`, and `Performance.isTitleAnnounced` says whether the title has been shown. Performing again after stopping clears the title for `Performance.titleClearing`, a second, before it shows again. In the Score asset, the ballad's title is followed by 2s of rest.

### Removed

- `WeightedSet`'s `MutableCollection`, `SetAlgebra` and `Comparable` conformances, `LinguisticTagOrder`'s `MutableCollection` conformance, and `Cycle`'s `Comparable` conformance. Assigning through `WeightedSet`'s subscripts could leave an element in the set twice and lose another, and assigning a new element added it rather than replacing one. Adding weights breaks the laws `SetAlgebra` promises, such as `x.union(x) == x`. Neither `<` was a valid ordering, and nothing used them; to order cycles, use `elements.lexicographicallyPrecedes(_:)`. `union`, `intersection`, `symmetricDifference`, `subtracting`, their `form…` versions, `insert`, `remove`, `update`, `contains` and `isDisjoint(with:)` remain as plain methods with the same weight arithmetic, so the music is unchanged. `SetAlgebra`'s initialiser from a sequence has gone; use `init(_:)` with an array.

- `WeightedSet.position(of:)`, which looked like a lookup but added a zero-weight slot for a missing element, and `existingPosition(of:)`. Use `firstIndex(of:)`, `weight(of:)` or `contains(_:)` to look an element up.

- The `Duration.seconds` extension, which only its tests used. It was easily confused with the static `Duration.seconds(_:)`.

- `Note.off`, the note's release velocity, and the `off:` parameter of `Note.init`. It was generated for every note but never used, as `AVAudioUnitSampler.stopNote` takes no velocity.

- `Part.speaker`, and the speaker written with each part of the ballad's lines, so `Part.init(speaker:string:pronunciations:isRecited:)` is now `init(string:pronunciations:isRecited:)`, and parts are equal when their strings are. Nothing used it: it was only the part's position in its line, restarting with the first speaker every line, whereas each part is recited by the next voice in turn.

- The `Recitable` protocol, which nothing used. Its `isRecited` setter changed copies of the elements rather than the elements themselves.

### Changed

- Each canto's title now appears before its first stanza is recited, as the stanza's music comes in after any intermission, rather than with the stanza's first part. A `Cue` that begins a canto has its `cantoIndex`, `Performance.announcedCantoCount` counts the cantos whose titles have been shown, and the performance view shows those cantos with `CantosView`'s `showsTitles`.

- The score is now written as a cue sheet, so each instrument can play its own stretches of time and the recitation can start whenever the score says. Its divisions are `###` headings grouped under the part of the ballad they belong to, in place of the `Each canto`, `Each stanza`, `Each line` and `Each later part` headings: `## Ballad`, with `### Title` and `### Introduction`; `## Canto`, with `### Title` and `### Intermission`; `## Stanza`, with `### First line`, `### Later line` and `### Intermission`; and `## Line`, with `### Later parts`. A list must come under a `###` heading, each `###` heading under a group that has it, and the groups and their divisions can come in any order. Messages name a division by its group and heading, such as `Stanza first line`. The introduction plays before the ballad, and the canto and stanza intermissions are played in full after each canto before the next and after each stanza before the next in the same canto, with nothing recited in them; where one canto ends only the canto intermission plays, and nothing plays after the last canto. Only the intermission for the largest division that begins is played, so the introduction replaces the first canto's, and a canto's replaces its first stanza's. The stanza's first line then has a cue of its own, so it can be recited straight after an intermission, while later lines have theirs. The score no longer names the voices: its Voices section and `Score.voices` have gone, and the two roles, First and Second, are now `VoiceNotation.standard`, so Settings always has a voice picker for each, and the turns follow the performance's speakers. Each division lists its instruments with the stretches they play, such as `- Viola: 0s–5s, 5s–end+1s at 60%`, and each line and later part says when the part is recited, such as `- Recite: 5.5s`. Times are counted from the start of the division, such as `5.5s`, or from the end of the recitation, as `end` or `end+1s`, which intermissions can't use. Each stretch plays at full volume unless given a percentage. An intermission lasts until its last instrument stops, or until the end of a rest written after that, such as `- Rest: 13s–15s`. An instrument plays one unbroken melody through all of its stretches, changing only its volume and picking it up again after a gap, so it's named only once in a division. Written with `continues`, such as `- Viola continues: 0s–end`, instruments carry on the melodies they played in the part before rather than starting new ones, unless an intermission came between or they didn't play in it; `Track.continues` records it, the performance passes on where each melody stopped, and `EventsSequence.next(continuing:)` and `Arranger.events(for:partDuration:continuing:)` take it. A part's turn ends once the recitation and every instrument have finished. In the Score asset, the cello, viola and violin come in a second apart to introduce the ballad, followed by 2s of rest; the string trio plays for 11s after each canto, followed by a second's rest, and for 5s after each stanza, followed by 2s of rest; the first line of each stanza opens with the trio for a second, then the violin and cello stop while the viola carries on at 90% and the part is recited; each later line opens the same way but with the trio for 3s and the part recited from 3s; and the viola plays on until a second after the part, or, carrying on its melody, under each later part of a line at 90% from the start of the part, with the part recited from 0.25s. `Score.introduction`, `canto` and `stanza` are now `Intermission`s, and `Interlude` now has a `recitationStart` and `tracks`, each a `Track` of instruments playing `Stretch`es between `Moment`s, in place of its `before` and `under` `Segment`s, so `Segment`, `Passage` and `InstrumentPart` have gone. `Event` is now an instrument's melody and stretches, and `Cue` holds its `intermission`, `intermissionLength`, `recitationStart` and `events` rather than `before` and `under`. `Arranger.events(for:partDuration:)` replaces `event(for:under:)` and `orchestration(for:lasting:)`, `Performance.play(_:on:alongside:)` and `playIntermission(_:lasting:on:)` replace `accompany(_:with:on:)`, and `SoundBank.play(notes:instrument:volume:while:)` plays from a cycle in place, so a melody can carry on from one call to the next.

- The Lexicon and Lines assets, and the preview and test fixtures, are now JSON, so `decodeAsset` always decodes JSON and its `format:` parameter and `AssetFormat` have gone. Pronunciations are written in cmudict's notation, such as `"S L IY1 P"`, so the lexicon tool's output can be pasted in, and a stressed consonant or unknown sound is now a decoding error rather than being dropped. Lines no longer store their string, as it's always the parts joined with spaces, so `Line.init(parts:string:tags:)` is now `init(parts:tags:)`, and its tags no longer default to none. The tags are still stored, as the app never tags at runtime. The Lexicon is 43 KB rather than 697 KB, and Lines 316 KB rather than 724 KB. FIVER's last vowel, which had no stress, is now unstressed as `ER0`, like every other vowel in the lexicon.

- Settings now has a voice picker for each of the score's roles, rather than First and Second pickers. `Speakers` has `roles` and `voices` in place of `firstSpeaker` and `secondSpeaker`, `init(roles:)`, and `speaker(forRole:)`, which wraps a role outside the roles around them. The turns are now kept by `VoiceTurns` for each performance, so `takeTurn()`, `resetTurns()`, `selectedSpeakers` and `maxSelectedSpeakers` have gone.

- `EventsSequence.next()` now returns a `Cue` for each part, holding the events played before and under the part, the part, and its speaker. `Event` has the `.play` and `.silence` cases, and a new `.accompany` case that plays until the part has been recited, and is `Sendable`; `.speak` has gone. `Performance` no longer infers which silences come before the recitation from their position, but plays a cue's `before` events and then its `under` events alongside the recitation.

- `Performance.init` takes a `score` rather than a `composer`, and by default uses the bundled score and creates speakers for its roles. `Performance.orchestration(duration:)` has gone; the `arranger` orchestrates the score's passages.

- The ballad's tag order is now counted from the tags stored with its lines when it loads, using the new `LinguisticTagOrder.init(lines:)`, so the weights can no longer drift from the lines. The Tags and TagsPreview assets have gone. Only tags that appear in the lines are listed, so Classifier and Idiom, which no line has, no longer appear in the tag order. The weights for Noun and PersonalName are now 1257 and 50, rather than the 1259 and 49 the Tags asset held, and the previews now show the same weights as the app, rather than the TagsPreview asset's out-of-date ones.

- `WeightedSet` is now a struct rather than a class, so copies no longer share their elements, and it has an explicit API for changing it. `setWeight(_:of:)` and `addWeight(_:to:)` change an element's weight, adding the element at the end if it's missing. `move(fromOffsets:toOffset:)`, `reverse()`, `shuffle()`, `shuffle(using:)` and `sort(by:)` rearrange the elements, and can't create duplicates. `LinguisticTagOrder` has its own `move(fromOffsets:toOffset:)`, which `TagListView` calls from `onMove` rather than moving tags through a binding.

- A weight is no longer part of an element's identity. A `WeightedLinguisticTag`'s `<` now orders tags by name alone, matching `==`, its hash ignores the weight, and its `id` is its name rather than its name and weight. The `Weighted` protocol documents the rule. The ballad's tag order still lists the heaviest tags first, as `LinguisticTagOrder` now sorts by weight itself. Two `WeightedSet`s, by contrast, are now equal only when they hold the same elements with the same weights, so `[A(1)]` no longer equals `[A(5)]`. The order of the elements and any zero-weight slots are ignored, and the hash matches. `isSubset(of:)`, `isSuperset(of:)` and their strict versions now compare weights: one set is a subset of another when each of its elements has at least as much weight in the other.

- `Cycle.currentIndex` can no longer be set from outside the cycle, as an index out of range crashed `next()`.

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

- `LinguisticTagger.linguisticTagsArray(string:)` and `Line.init(parts:)` now throw `LinguisticTaggerError.tagSchemeUnavailable` when the tag scheme isn't available on the device, rather than tagging every word as an other word.

### Added


- The performance is now written as a score, `Score`, in Markdown in the app's Score asset, `Score.md`, which reads in the order it's performed. The score has an introduction, and interludes that open each canto, stanza, line and later part of a line every time one begins. Each interlude lists the music and rests to play before the part is recited, which the part waits for, and those to play under it, which start as it is recited. Each passage of music lasts a number of seconds or, written without them, as long as the part takes to recite, and names its instruments, and for each instrument a `NoteSelection` of the tunes, vector width and set operations its notes are drawn from. The score also names the voices' roles, which take turns, one part each, starting with the first; `VoiceTurns` keeps track of them. In Markdown, the title comes first, then the voices, each part being recited by the next of them, then the introduction, each canto, each stanza, each line and each later part, each a list of what plays in turn before the part, ending with `Recite`. What follows `Recite, with` plays under the part, as in `- Recite, with Viola at 60%`, and lengths are written as `for 7s`. Every instrument in a Markdown score selects its notes in the standard way. `Score.init(markdown:)` reads it, throwing a `ScoreError` with the line of any mistake, and `assetData(_:from:)` gives a data asset's bytes. The Score asset is the `Score.standard` score, with the viola playing under every part, at a volume of 0.6, for as long as it takes to recite. Otherwise it performs the ballad as before, except that the voices now take turns starting with the first rather than the second, and that the first part of the ballad, and of each canto, stanza and line, now waits for the music and the second's rest that open it to finish, rather than being recited over them. `Arranger` composes the score's passages, preparing a `Composer` for each note selection once.

- Each instrument in a passage of the score can have a `volume` from 0, silent, to 1, full, written in the score as a percentage, such as `Viola at 50%`. Left out, it's 1. The velocity of each note is scaled by the volume as it's played, so the notes keep their varying dynamics, only softer, and the same instrument can play at different volumes in passages that overlap. A volume outside 0% to 100% is reported when the score is read. `Assignment`, `Instrument.play(notes:duration:volume:on:)`, `SoundBank.play(notes:duration:instrument:volume:)` and `Composer.composeAssignment(instrument:duration:volume:)` take the volume, and `NoteVelocity.scaled(by:)` scales a velocity.

- `Composer.init(selection:)`, and an `operations` parameter on `Composer.init(tunes:vectorWidth:)`, choose the set operations the notes are drawn from. A selection that leaves no patterns to draw from now stops with a message when the composer is created, rather than when a note is first composed.

- `decodeAsset` takes a `format`, `.propertyList` or `.json`. It defaults to `.propertyList`.

- `InstrumentName` is `CaseIterable`, and is written in the score by its description, such as "Violin". `TuneName` names the built-in tunes.

- The performance can be paused and resumed. `Performance` has a `state` of `.stopped`, `.playing` or `.paused`, replacing `isFinished`, and `play()`, `pause()`, `resume()` and `stop()` methods. Pausing holds the voice at the next word and holds any sounding notes, which play out the rest of their length on resume.

- `PauseGate`, which tasks wait at while it's paused, and whose `sleep(for:)` doesn't count time spent paused. Notes and the silences between parts are timed with the sound bank's gate.

- `PerformanceView` has a play/pause button and a stop button, which is disabled when the performance is stopped.

- `WeightedSet.weightedRandomElement()` selects an element with a probability proportional to its weight, never selecting elements without a positive weight.

- `LinguisticTagger.isTagSchemeAvailable` and `checkTagSchemeAvailability()` report whether the `nameTypeOrLexicalClass` tag scheme is available for English on the device. The Natural Language framework only lists a tag scheme once its assets are loaded into the app, so a scheme that isn't listed is tagged with once before it's checked again. Its errors are `LinguisticTaggerError`.

### Fixed

- The instruments coming in during the introduction no longer interrupt those already playing. Each instrument used to load its preset as it first played, while the others sounded; now, before the introduction, `SoundBank.warmUp(_:)` loads every instrument in `Score.instruments` and starts the engine. The warm-up is queued with the performance's other engine changes, so stopping during it still leaves the engine stopped.

- Speech should stutter less as the voices take turns. `SpeechSynthesizer` now speaks each voice through an `AVSpeechSynthesizer` of its own, rather than switching one synthesizer's voice for every part, which could leave its audio queue running dry and filling the gaps with silence. Pausing, resuming and stopping act on whichever synthesizer spoke last. As the performance starts, `SpeechSynthesizer.warmUp(_:)` synthesizes a few words in each role's voice to audio buffers that are thrown away, rather than speaking them, so that each is ready by the end of the introduction; an utterance in the same voice cuts its warm-up short.

- Playing again after stopping the performance now uses the score's instruments, such as the violin, viola and cello, rather than the sampler's default sound. Stopping the audio engine empties the samplers' presets, so `SoundBank.stopEngine()` now releases the samplers, and each instrument is loaded afresh when it next plays. Presets are also loaded one at a time across every `SoundBank`, as Core Audio aborts when two sound banks load them at once.

- The Pad Polysynth instrument was described as "Pad Warm", the same as the instrument before it.

- The Performance and Settings tabs now have icons on iOS, rather than showing only their titles.

- `WeightedSet.remove(_:)` no longer leaves a negative weight: it stops at zero, as `subtracting(_:)` does. A member with no weight, such as `Element(rawValue:)`, now removes the element's whole weight rather than nothing, and `remove` returns the element as it was before rather than the reduced element. `insert(_:)` returns the stored element with its new total weight, and doesn't report an insertion when the element still has no weight. `update(with:)` replaces the element's weight rather than adding to it, and returns the element as it was before. `isEmpty` no longer counts zero-weight slots, so it agrees with `contains(_:)`; `count` still includes them.

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

- Performing again after stopping now always starts with the same speaker. The speakers' turns previously carried on from the last performance, so it could start with either. `Speakers` has a `resetTurns()` method, which `Performance.play()` calls.

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

[Unreleased]: https://github.com/michaelthscott/The-Ballad-of-Connaught-Square/compare/v1.1...HEAD
[1.1]: https://github.com/michaelthscott/The-Ballad-of-Connaught-Square/compare/v1.0...v1.1
[1.0]: https://github.com/michaelthscott/The-Ballad-of-Connaught-Square/releases/tag/v1.0
