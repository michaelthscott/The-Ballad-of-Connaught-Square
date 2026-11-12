# ``ConnaughtSquare``

Perform The Ballad of Connaught Square, recited by synthesized voices over a generated string accompaniment.

## Overview

The ballad is built from words overheard in Connaught Square: the conversations of the police
officers who guard it, caught by a passer-by. Connaught Square arranges those lines into a ballad
and performs it.

### Arranging the words

Each ``Line`` of the ballad is made of one or more ``Part``s, and each part carries the
pronunciations of its words, taken from the ``Lexicon``. When the lines were prepared, the
``LinguisticTagger`` tagged every word by its lexical class, such as noun, verb or personal name,
and the tags are stored with the lines.

The ``Ballad`` orders its lines in two passes. First it sorts them by their tags, following the
``LinguisticTagOrder``, which counts the lines' tags and initially lists the most frequent first. Then it picks lines
so that they rhyme as much as possible, aiming for the ABAB pattern of a ballad's quatrains.
The lines are grouped four at a time into ``Stanza``s, and the stanzas are grouped into
``Canto``s by the tag their first line starts with.

Because the arrangement follows the tag order, choosing a different tag order or reordering the
tags in the settings rearranges the whole ballad.

### Scoring the accompaniment

The music is written in a ``Score``, read from a Markdown asset laid out like a cue sheet. It has
an introduction played before the ballad, and intermissions played between cantos and between the
stanzas of a canto, each in full with nothing recited. It also says what happens as each part
begins: one passage for the first line of a stanza, one for the first part of each later line, and
one for each later part of a line. Each of these says when the part starts being recited, and lists
the instruments and the stretches of time they play, at a volume. A time can be counted from the
start of the passage or from when the recitation finishes, so the music can play under a part for
as long as it takes to recite. An instrument can also carry on the melody it played in the part
before.

### Composing the melodies

The ``Composer`` writes new music from two traditional tunes, The Sash My Father Wore and
The British Grenadiers. It breaks each ``Tune`` into short sequences of note intervals and
durations, held in ``WeightedSet``s that count how often each sequence occurs. It then combines
the tunes' sets by union, intersection or symmetric difference, and draws from the result with a
probability proportional to each sequence's weight. A ``NoteSelection`` says which tunes, which
sequence length and which combinations an instrument's notes are drawn from.

The ``Arranger`` turns the score's passages into ``Event``s, one for each ``Instrument``, having a
composer write each one a melody long enough for its stretches, or carrying on the melody it
played in the part before.

### Performing the ballad

A ``Performance`` walks through the ballad part by part. Before it starts, it loads every
instrument in the score into the ``SoundBank`` and readies the voices. An ``EventsSequence`` then
produces a ``Cue`` for each part: any intermission that comes before it, the events that play
around it, when its recitation starts, how the part is to be declaimed, and the ``Speaker`` who
recites it. The voices take turns to recite the parts, one part each, in the roles the voices are
chosen for in the settings. Each cue's intermission plays in full first, then the part is recited
while the instruments play their stretches through the ``SoundBank``'s samplers, and the cue ends
once the recitation and every instrument have finished. Each canto's title, and the text of each
part as it is spoken, appear in the Performance tab.

The performance can be paused and resumed. A ``PauseGate`` holds the voices and the
accompaniment in place, and time spent paused doesn't count towards any note or silence.

### Reciting the parts

The parts are recited as recitative rather than plainly spoken. For each part the cue makes a
``Declamation``, which looks up each word's stress in the ``Lexicon`` and shapes the part: the pitch
rises to the first stressed word and drifts down, stressed words stand out and are slowed, and the
voice pauses at commas, at each `…` and between parts. A line ends with a fall, a part that trails
off is left hanging, and a question to be answered yes or no rises from its last stressed word.
The whole part is pitched towards the note its music plays most often, as a register rather than
note by note, and the music is composed to last about as long as the declamation is expected to.
How far the pitch moves, the rates and the pauses come from a ``DeclamationStyle``, which is tuned in
the settings.

The ``SSMLRenderer`` writes the declamation as Speech Synthesis Markup Language, and the
``SpeechSynthesizer`` speaks it, through an audio engine of its own so that each voice can stand to
one side in stereo. ``VoiceSelection`` chooses the voices: the enhanced downloads of Daniel and
Arthur, which speak the markup smoothly, with other voices standing in until they're installed.
Each role's volume, and the music's, are set in the settings, so the voices can be balanced
against each other and against the music.

## Topics

### Performing

- ``Performance``
- ``EventsSequence``
- ``Cue``
- ``Event``
- ``PauseGate``

### Reciting

- ``Declamation``
- ``DeclamationStyle``
- ``SSMLRenderer``
- ``SpeechSynthesizer``
- ``Speakers``
- ``Speaker``
- ``VoiceSelection``
- ``VoiceNotation``

### Words

- ``Ballad``
- ``Canto``
- ``Stanza``
- ``Line``
- ``Part``
- ``Lexicon``
- ``LinguisticTagger``
- ``LinguisticTagOrder``
- ``Rhyme``

### Music

- ``Score``
- ``Arranger``
- ``Composer``
- ``NoteSelection``
- ``Tune``
- ``Instrument``
- ``Note``
- ``SoundBank``
- ``WeightedSet``
