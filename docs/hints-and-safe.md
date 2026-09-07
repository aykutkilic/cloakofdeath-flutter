# Hints and safe interaction — 2026-09-08

Purpose: offer practical guidance toward the next useful puzzle without requiring
players to type an exact command or read a full solution.

## Evidence and wording

The user supplied the [Gaming After 40 playthrough](https://gamingafter40.blogspot.com/2013/11/adventure-of-week-cloak-of-death-1984.html).
Its narrative includes failed experiments and later corrections, so the current
source-verified engine and constrained walkthrough remain authoritative for
prerequisites, navigation, inventory load, and hazards. Following user feedback,
hints now name useful items, explain what they do, and offer command-level help
when another hint is requested. They no longer hide recipes behind metaphors.
The user explicitly allowed the safe clue to mention **1327**.

Examples: the knife permits passing the rat without fighting; the Bible permits
the entrance stairs; dropping the chest in the dark corridor holds the cellar
door despite its broken latch. Coal and oily rag must be dropped together in the
tunnel and lit with carried matches to frighten the dog. The crucifix uses the
silver bar cut with the garage saw, plus silver wire, in the workshop; the heavy
iron instead holds the guest-bedroom cord. These distinctions were checked in
the engine, rather than inferred from item names or the user's recollection.

## State-derived guidance

`AdventureHints.next` is a pure read of engine state, room names, and existing
exploration history. It prioritizes
pending combination input and immediate danger, then unfinished puzzle milestones.
It accounts for darkness, fuel conservation, cupboard reach, cellar preparation,
the dog, hatch and passage, silver crafting, the cord mechanism, blessing,
exorcism, the safe, and escape. Dropped equipment hints refer to its actual room.
These are curated puzzle hints, not a search-based solver or proof that every
arbitrary save remains winnable.

Completion applies to both primary hints and their details. Engine flags and
object transformations suppress solved puzzles (dog, hatch, bar cutting, cross,
safe, and gate); known upstairs visits suppress the original Bible/stairs clue
even after the Bible is dropped and the player returns downstairs. The adapter
supplies the already-persisted exploration set, with current upstairs location
also accepted as evidence. No second completion tracker or save schema is added.
Legacy saves without exploration cannot reconstruct unrecorded earlier visits.

Equipment recovery is distinct from re-solving a puzzle. Bible reminders for
the unfinished ritual or iron transport have their own IDs and do not reuse
the initial study/stairs details. A matches reminder cannot resurrect a completed
dog puzzle. Already-cut bar pieces and a relocated goblet are retrieved rather
than recommending another saw or repeating the cord mechanism. An open passage
and a revealed safe key lead onward rather than repeating discovery commands.

`AdventureHint` carries the state-selected detail list. `variants` only combines
that snapshot with its primary text; it cannot append obsolete item-catalog
details later. Cupboard setup, chest positioning, and other completed substeps
are omitted where their current state already satisfies the prerequisite.

There is no persisted hint cursor or extra command transaction. Repeated hints
do not advance time, consume candle fuel, change inventory, or append to the
journal. Restored saves receive the same hint as the equivalent live state.
Temporary UI selection and partially entered digits remain local widget state.

## Finite hint progression

The old implementation alternated two phrasings forever, with an echo of the
primary text as its fallback. `AdventureHints.variants` now returns a finite,
deduplicated sequence: a practical primary clue followed by additional details
or commands. Steps without authored details have just one hint, not filler.

`GameState.takeHint` advances session-only offsets keyed by the primary ID and
complete selected text sequence, so changed prerequisites or dropped-item
locations have their own guidance, even when only the detail list changes.
It never wraps around. `hasMoreHints` disables Another hint after the last entry,
labeling it All hints shown. Reopening an exhausted step explains that all its
guidance has been seen instead of showing the first clue again. Progress can
unlock a different sequence; resetting the game clears offsets. The pure
`nextHint` remains deterministic and independent of these presentation offsets.

Cellar door-propping has its own hint ID, separate from finding/breaking the
chest, so later details do not send players back to an already-finished task.

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
Additional tests verify the named prerequisites and complete dog/crucifix
recipes, finite deduplicated progression, dialog reopen/exhaustion, refreshed
guidance after progress, and reset behavior.
The full walkthrough also checks that solved puzzle IDs never return and no dog
advice appears after it is frightened. Focused completion tests cover upstairs
history through return/drop/reload, ritual-specific Bible recovery, matches after
the dog, partial crafting and safe completion, and detail-only progress changes.

Layout coverage includes 320-pixel phones, short landscape, and 1.6x text.
Preview images use the existing `PREVIEW_DIR` and `PREVIEW_FONT` test options;
Flutter's cached material fonts provide both readable Roboto and icon glyphs.
SDK-cache writes require sandbox escalation in this workspace. Rendered widget
evidence does not establish live-device acceptance.
