# Game logic audit — 2026-09-07

## Evidence and precedence

The requested comparison uses the [supplied Gaming After 40 walkthrough](https://gamingafter40.blogspot.com/2013/11/adventure-of-week-cloak-of-death-1984.html),
the local `tools/solution.txt` (CASA route with its west-exit correction), and the
original Atari cassette `tools/Cloak of Death.cas`. The blog is a retrospective
playthrough referencing CASA, rather than publisher-authored documentation.
Use the cassette program to resolve exact counters and prerequisites; use the
playthrough as independent evidence for the intended puzzle sequence.

Cassette SHA-256: `79a8426d2978a3b39d8c8f24cb35e0a146f6d33119ceb207ddd07553aea3b1db`.
The original material in `tools/` is local and gitignored. Reproduce the evidence
without modifying it:

```sh
python3 scripts/inspect_original.py 'tools/Cloak of Death.cas'
```

The script removes cassette framing, reads tokenized BASIC DATA, and reports
initial object slots, all 26 indoor exit rows, and selected rule-line bytes.
It is an evidence extractor, not a BASIC interpreter or emulator. `Cloak of
Death.bas` is a human transcription with errors. In line 32060 it omits a zero
before the cupboard slot: the cassette actually sets P(36)=0, P(37)=7,
P(38)=26, P(39)=5. Thus the cupboard starts hidden, the desk is in the study,
the dog guards the tunnel gates, and the cellar door starts in the corridor.
The cassette also confirms line 14 tests **O > 28**, not **P(O) > 28**.

## Verified rules and repairs

| Rule | Original evidence | Implemented behavior |
| --- | --- | --- |
| Carrying | 1410, 1450–1460, 1730–1750 | Six units maximum. Iron costs four; other portable items cost one. Check both pickup orders and release all four units when dropping iron. |
| Fuel | 410–450, 2430, 2620, 32100 | LC starts at 1 and expires at 200: 199 burning turn completions, including LIGHT itself. Relighting never resets fuel. Extinguishing pauses consumption; expiry removes the candle. |
| Fuel warnings | 420 | Warn at 10 remaining and at 4, 3, 2, 1. |
| Turn accounting | 260–290, 400, 640, 7200 | A command, including failed movement or invalid input, advances once. Inventory and blank input are free. OPEN SAFE plus its combination response together complete one turn. |
| Darkness | 400, 600, 1200 | Indoor rooms 15–26 are dark unless a lit candle is carried or lies in that room. A dropped candle continues burning even while the player is elsewhere. Looking cannot reveal hidden objects in darkness. |
| Rat and upstairs | 1080–1086, 4600–4620 | Knife needed for corridor entry every time; feeding uses bread without removing the rat. Bible needed to go upstairs until the cloak is exorcised. |
| Matches | 1470–1480, 5810–5820, 1120 | First pickup requires standing on the dropped chair. Moving or picking the chair up clears that stance. Later retrieval of already reached matches needs no chair. |
| Chest and cellar | 1430–1460, 1740, 1798, 2030–2045, 1095–1130 | Chest is portable. Unlocking consumes the small key. A chest in the corridor holds the unlocked door open; without it the door slams behind the player and the broken latch traps them below. |
| Secret passage | 1090, 1140–1150, 5600–5610 | Discovered book must be on the library shelf to open the passage. PUSH TABLE enables room 17's west exit to 16. No unconditional down shortcut. Reentering the library resets the return mechanism. |
| Hatch | 1105, 8800–8820 | Remove nails with carried hammer in the pool room, then enter the hatch for the wire. |
| Crucifix | 3400–3430, 6200–6220 | Cut the held bar with the held saw in the workshop, then combine the pieces and wire there. Both ingredients are consumed; the crucifix appears in the room. Cutting pieces again destroys them. |
| Cord and iron | 1460, 1750, 5620, 1120 | Pull the guest-bedroom cord, then drop iron there before leaving. This opens the master-bedroom annexe. Picking the iron up closes it again. |
| Goblet and water | 1500–1590, 1770–1790 | Examine sink to discover the water. Fill carried goblet; Bible + crucifix bless it. Blessing also occurs when the last missing relic is picked up. Filled/holy/empty goblet are one physical container, separate from the sink supply. Original full-load GET refusal also applies to filling. |
| Dog | 2080, 2420–2470, 1110 | Requires matches in hand and coal + oily rag dropped together. Burning removes both and scares the dog. Burning the rag alone destroys it. The dog blocks gate unlocking and escape until frightened. |
| Cloak | 460–490, 1100, 6000–6040 | Bible + crucifix permit entry. Entry is approach stage 1, the next action stage 2, the next fatal unless exorcism succeeds first. Invalid commands count; leaving does not reset the approach. Exorcism needs Bible, crucifix and holy water, consumes the water, and returns the empty goblet. Bread and wine are not prerequisites. |
| Safe | 1430, 2110–2130, 1325 | Taking the painting reveals a safe fixed to that room. Opening prompts for 1327. Wrong response kills; unsolicited 1327 cannot open it. Examining the open safe reveals the skeleton key, also accepted as KEY after the small key is consumed. |
| Ending | 1110–1115, 510–530 | Unlocking gates does not win immediately. Entering the courtyard wins. Death and victory stop further game commands and survive saves. |

## Architecture decisions

`AdventureEngine` owns deterministic rules and a single authoritative object
location map. Inventory and carrying load are derived, avoiding the old duplicate
inventory/location state that retained consumed bars, goblets, candles, and wire.
Every command applies its effects and then completes the timed turn once.
`GameState` handles Flutter notifications, transcript formatting, and persistence;
public navigation calls the same command path as the text input and minimap.

Stateful exits are projected by the engine on top of generated room data.
Rendering bytecode and the generated graphics file were not edited for this audit.
Object menus use contextual actions, exposing GO, MAKE, REMOVE and EXORCISE.
The inventory badge shows carrying units; the debug dialog distinguishes load
from the actual number of items.

Save schema 2 includes fuel, stance, reached matches, cord/door/table state,
cloak approach, pending combination, and terminal outcome. Snapshots are captured
synchronously and writes run in order, so rapid input cannot save an older turn
over a newer one. Legacy saves reconcile their inventory/location copies, repair
the known starting-location mistake, cap obsolete fuel at 199, and place excess
carried objects in the current room. A legacy zero-fuel unlit candle is treated
as unused because the previous schema did not distinguish unused from exhausted.
Old saves cannot reconstruct fuel already erased by the former relighting bug.
Start a new game for an unambiguous original-rules playthrough.

## Deliberate compatibility boundaries

- The original exorcism line only rejects locations below 15, allowing a remote
  exorcism exploit in other dark rooms. Require the cloak's bedroom instead.
- Retain meaningful original dead ends: wasting materials, exhausting the candle,
  or entering the unpropped cellar can make escape impossible. Solvability means
  a valid complete route exists, not that every sequence can recover.
- GET still uses object presence rather than visibility, matching BASIC's
  presence subroutine: known objects can be picked up by name in darkness.
  The UI hides them and LOOK cannot discover them there.
- DROP WATER empties the carried goblet; DROP GOBLET (or an explicit filled
  container name from the mobile UI) drops that container. THROW CANDLE puts it
  out; ordinary DROP preserves a lit candle in the room.
- Modern full names and object actions are supported alongside the important
  original abbreviations. This is not a byte-for-byte parser emulator; original
  randomized rejection text and blank-input graphics toggling are not reproduced.
  LOOK BOOK also exposes its title to make the tap interaction useful.
- The courtyard is displayed as outdoors, without the indoor darkness rule.
  Source line 510 ends the original before another normal room description.

## Verification and working notes

The pre-change walkthrough and seven existing logic tests passed despite the
missing constraints. After repair, the old test failed at its unconditional
room-17 down exit, and its dog-location assertion failed against cassette data.
Both tests were corrected to reflect source evidence, not relaxed to allow the
old bypasses. The route fixture includes CASA's corrected W, D, W return from
the pool room through the attic/passage to the library.

The complete route runs from a fresh game without injecting room, inventory,
flags, or fuel; every pickup is asserted and load never exceeds six. A second
execution restores a serialized snapshot after every command. Focused tests
cover negative prerequisites, fuel boundaries, transformations, deaths, and
terminal persistence. Widget tests tap corridor navigation, crucifix crafting,
and exorcism menus. See development history for recorded test results.

Tool lessons: extracting ASCII from `cas_dump.txt` interleaves framing and can
misalign dictionaries. Read `.cas` records directly. BASIC saved memory addresses
map to file offsets with -258 for this image, not -256 or -242. The format tool
successfully formatted files but initially returned failure while writing Dart
telemetry outside the workspace. Flutter tests needed an approved SDK-cache write
outside the workspace; that was an environment restriction, not a game failure.
No emulator comparison or physical-device run was performed in this audit.

## Mechanism feedback — 2026-09-08

Puzzle effects are reported by the engine transaction and reach the journal via
`GameState.processCommand`, so typed commands and object/inventory actions give
the same feedback without extra turns or presentation-owned puzzle state.

- Dropping iron in the guest bedroom after pulling the cord confirms that the
  iron holds it taut and the mechanism settles into place. Ordinary iron drops
  do not claim success; the existing pull/weight prerequisites remain intact.
- Dropping the chest beside a closed cellar door reports placement only. Opening
  the door with the chest already there confirms it is keeping the door open.
  Dropping the chest after opening gives the same confirmation.
- Opening or checking an open, unpropped cellar door warns that it will slam shut
  on entry and that the broken latch prevents reopening it from inside. Entering
  without the chest reports both the slam and why the player cannot reopen it.

Decision: the engine already supported both chest-placement orders. Share the
open-door status message between opening and dropping instead of adding flags
or reimplementing puzzle conditions in UI widgets. Extend the existing constraint
and full-walkthrough checks to cover truthful feedback, return travel and journal
propagation; preserve the original key consumption and turn accounting.
