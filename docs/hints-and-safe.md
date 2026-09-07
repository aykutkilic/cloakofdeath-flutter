# Hints and safe interaction — 2026-09-08

Purpose: offer a gentle nudge toward the next useful puzzle without requiring
players to type an exact command or read a full solution.

## Evidence and wording

The user supplied the [Gaming After 40 playthrough](https://gamingafter40.blogspot.com/2013/11/adventure-of-week-cloak-of-death-1984.html).
Its narrative includes failed experiments and later corrections, so the current
source-verified engine and constrained walkthrough remain authoritative for
prerequisites, navigation, inventory load, and hazards. Hints are original prose
about relationships between objects; they do not emit solution commands. The
user explicitly allowed the safe clue to mention **1327**.

## State-derived guidance

`AdventureHints.next` is a pure read of engine state and room names. It prioritizes
pending combination input and immediate danger, then unfinished puzzle milestones.
It accounts for darkness, fuel conservation, cupboard reach, cellar preparation,
the dog, hatch and passage, silver crafting, the cord mechanism, blessing,
exorcism, the safe, and escape. Dropped equipment hints refer to its actual room.
These are curated puzzle hints, not a search-based solver or proof that every
arbitrary save remains winnable.

There is no persisted hint cursor or extra command transaction. Repeated hints
do not advance time, consume candle fuel, change inventory, or append to the
journal. Restored saves receive the same hint as the equivalent live state.
Temporary UI selection and partially entered digits remain local widget state.

Carrying constraints influence ordering: once the cross exists, the iron/goblet
stage must allow the player to leave relics and matches behind. Otherwise hints
would repeatedly request equipment that prevents carrying the four-unit iron.
The Bible is still necessary at the entrance stairs. The passage return clue
uses the current table flag, which resets on entering the library.

## Combination entry

The overlay observes `awaitingCombination`; it is not tied to a particular
button. Typed OPEN SAFE, its object menu, and restored pending saves all display
the same four-slot keypad. Digits, clear, and backspace are local edits; a separate
button submits exactly four digits through `GameState.processCommand`. Hardware
digit keys, backspace, and Enter also work. Leading zeros remain significant.

The normal screen is covered and excluded from focus and accessibility while the
engine awaits its response. This prevents an accidental direction or LOOK action
from being interpreted as a wrong combination. A lightbulb remains available
inside the panel. There is no cancellation command in the original pending-input
transaction. Wrong four-digit submissions retain the engine's fatal outcome,
stated beside the submit control. OPEN plus the submitted code remains one turn.

The brass digit slots and lock icon reuse the app theme. The panel scrolls on
short or large-text screens; controls have at least 48-pixel touch targets. Digit
state has a live accessibility label. Navigation now orders W before E, with
the original direction labels, icons, destinations, and engine semantics intact.

## Validation and tool experience

Tests cover the complete source-constrained route with non-mutating hints and
restore equivalence at every step, explicit major puzzle milestones, dropped
items, out-of-order completion, and iron carrying space. Widget tests cover
typed/menu/restored safe entry, correct/fatal attempts, keyboard editing, clear,
digit limits, hints without turn/fuel costs, and westward navigation.

Layout coverage includes 320-pixel phones, short landscape, and 1.6x text.
Preview images use the existing `PREVIEW_DIR` and `PREVIEW_FONT` test options;
Flutter's cached material fonts provide both readable Roboto and icon glyphs.
SDK-cache writes require sandbox escalation in this workspace. Rendered widget
evidence does not establish live-device acceptance.
