# ``ConnaughtSquare``

Perform The Ballad of Connaught Square, recited by synthesized voices over a generated string accompaniment.

## Overview

The ballad is built from words overheard in Connaught Square: the conversations of the police
officers who guard it, caught by a passer-by. Connaught Square arranges those lines into a ballad
and performs it.

### Arranging the words

Each ``Line`` of the ballad is made of one or more ``Part``s, and each part carries the
pronunciations of its words, taken from the ``Lexicon``. The ``LinguisticTagger`` tags every word
by its lexical class, such as noun, verb or personal name.

The ``Ballad`` orders its lines in two passes. First it sorts them by their tags, following the
``LinguisticTagOrder``, which initially lists the most frequent tags first. Then it picks lines
so that they rhyme as much as possible, aiming for the ABAB pattern of a ballad's quatrains.
The lines are grouped four at a time into ``Stanza``s, and the stanzas are grouped into
``Canto``s by the tag their first line starts with.

Because the arrangement follows the tag order, reordering the tags in the Settings tab
rearranges the whole ballad.

### Composing the accompaniment

The ``Composer`` writes new music from two traditional tunes, The Sash My Father Wore and
The British Grenadiers. It breaks each ``Tune`` into short sequences of note intervals and
durations, held in ``WeightedSet``s that count how often each sequence occurs. It then combines
the tunes' sets by union, intersection or symmetric difference, and draws from the result with a
probability proportional to each sequence's weight. The music it composes is an
``Orchestration`` for violin, viola and cello, played through the ``SoundBank``'s samplers.

### Performing the ballad

A ``Performance`` walks through the ballad part by part. An ``EventsSequence`` produces the
``Event``s for each part: a passage of music whose length depends on whether the part begins the
ballad, a canto, a stanza or a line, a short silence, and the part itself. Two ``Speakers`` take
turns to recite the parts using the system's British English voices, and the text appears in the
Performance tab as it is spoken.

The performance can be paused and resumed. A ``PauseGate`` holds the voices and the
accompaniment in place, and time spent paused doesn't count towards any note or silence.

## Topics

### Performing

- ``Performance``
- ``EventsSequence``
- ``Event``
- ``Speakers``
- ``Speaker``
- ``SpeechSynthesizer``
- ``PauseGate``

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

- ``Composer``
- ``Tune``
- ``Orchestration``
- ``Instrument``
- ``Note``
- ``SoundBank``
- ``WeightedSet``
