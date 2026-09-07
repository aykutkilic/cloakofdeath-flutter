# Development history

## 2026-09-08 — Practical hints without repetitive cycling

Purpose: make the lightbulb useful when players need actual prerequisites and
actions, rather than two cryptic phrasings of the same advice.

- Rewrote clues to name equipment and its purpose: knife for the rat, Bible for
  the stairs, chest to prop the corridor door, coal plus oily rag and matches for
  the dog, and cut silver bar plus wire for the crucifix. More detailed entries
  include commands and safety warnings. The heavy iron is explicitly reserved
  for the bedroom cord, not confused with the silver bar.
- Replaced modulo cycling and the fallback echo with finite, deduplicated hint
  sequences. Another hint advances to new details, then becomes All hints shown.
  Reopening an exhausted step explains exhaustion instead of repeating its first
  clue. Progress and changed item locations can unlock new guidance; reset clears
  session offsets. Hint reads still consume no turns, fuel, or journal entries.
- Split cellar propping from chest discovery so later guidance does not recommend
  repeating the chest-opening task. Renamed the dialog Hints for your next step.
- Checked recipes and locations against the engine and constrained walkthrough,
  including the garage saw, letter revealed by taking the Bible, and westward
  library return after pushing the pool table. [Design notes](hints-and-safe.md)
  record the revised wording and progression contract.
- Validation: the full 100-test suite and application/test static analysis passed.
  Added recipe/prerequisite, uniqueness, exhaustion/reopen, progress, and reset
  checks; existing phone, landscape, and enlarged-text layout tests passed.

## 2026-09-08 — Automatic candle management during map travel

Purpose: remove repetitive candle commands when revisiting rooms without
bypassing the adventure's equipment, fuel, or timed hazards.

- Map plans now light a carried candle before darkness and extinguish it in
  bright rooms. Matches and remaining fuel are required for lighting; dropped
  items are not manipulated remotely. Ordinary manual movement is unchanged.
- Candle actions run through the same engine commands in previews and travel,
  preserving turn costs, cumulative fuel, journal entries, and ordered saves.
  Leaving the haunted bedroom happens before extinguishing; the final exit
  extinguishes before the engine becomes terminal.
- Replaced movement-only BFS with turn-cost buckets and turn/fuel dominance:
  automatic commands make different route edges cost different numbers of turns.
  Shared the engine's room-light requirement with the UI adapter and planner.
- Validation: all 96 tests passed, including five new candle/route regressions;
  full application/test Dart analysis reported no issues. Tests cover exact
  manual-equivalent saved state, relighting without fuel reset, missing equipment,
  low fuel, cloak timing, the final exit, and total-turn route selection.
  SDK-backed checks required sandbox escalation. See [map design notes](exploration-map.md).

## 2026-09-08 — Separate touch map inspection and travel

Purpose: let mobile players inspect a room without accidentally moving there.

- Single touch taps show room details; double-tap or long press requests travel.
  Mouse hover and single-click travel remain available. The interaction wrapper
  uses actual pointer kinds rather than platform or viewport assumptions.
- Current or blocked rooms show details without moving. Travel still uses the
  existing route validation and normal engine transactions; gesture state and
  tooltips are not persisted. Updated the map's on-screen gesture instructions.
- Validation: all 14 focused map/hint tests passed, including phone tap-only
  inspection, both touch travel gestures, blocked stairs, and mouse hover/click.
  Targeted Dart analysis reported no issues.

## 2026-09-08 — Compact map nodes and hover details

Purpose: reduce oversized room cards and long empty corridors while keeping
room identities readable at a glance.

- Replaced large cards with 48-pixel nodes bearing short room names. Full names,
  room contents, travel cost, and blocked-route explanations appear on hover or
  long press. The current room keeps its brass outline.
- Collapsed unused map rows/columns while retaining directional ordering;
  reduced grid spacing and dialog size. Removed the permanent detail panel and
  shortened floor-link controls to U/D with destination tooltips.
- An initial numbered-node design was revised to short names following the
  user's visual feedback. Dark visited rooms say Unlit until actually seen.
- Validation: all 11 focused map tests and targeted static analysis passed.
  Inspected compact ground/first-floor renders on desktop and phone; hover and
  long-press tests verify details appear without expanding the nodes.

## 2026-09-08 — Rotating clues and exploration map

Purpose: avoid repeating a single tip and provide a useful map of discovered
rooms with room contents and movement that respects the adventure rules.

- Added per-puzzle clue rotation across lightbulb openings and an Another hint
  action. Rotation is session-only and costs no game turns or candle fuel.
- Added persisted exploration knowledge, floor-based room layouts, hover/hold
  contents, directional and stair connections, pan/zoom, and click-to-travel.
  Travel previews simulate the real engine; executed routes consume the normal
  turns and fuel and cannot skip unvisited rooms or locked puzzle conditions.
- Legacy saves reveal only their current room. Dark visits remain unnamed until
  seen in light; unrevealed objects stay hidden. On phones, display settings moves
  into the game menu to keep room for the map button.
- [Map design notes](exploration-map.md) record state ownership, layout decisions,
  route semantics, migration, and verification experience.
- Validation: the full 87-test suite passed. After mobile zoom refinements,
  all 11 focused map/hint tests passed, including an added fuel/save test.
  Inspected desktop, phone, and landscape map renders with real fonts.
  Final Flutter analysis reported no issues after waiting for the shared SDK
  startup lock; no other process or lock file was modified.

## 2026-09-08 — Repository and playable demo links

Purpose: connect players to the source project and let repository visitors play
without installing the app.

- Added View on GitHub under Game menu → About the game, using Flutter's
  `url_launcher` Link widget for browser links and native platform handling.
  Web links open in a new tab to preserve the active game.
- Placed the GitHub Pages playable demo link directly below the README title.
- Validation: static analysis and the release web build with the GitHub Pages
  base path passed. Added the platform plugin registrations generated by
  Flutter dependency resolution; no gameplay state changes were required.

## 2026-09-08 — Contextual hints, safe keypad, and compass ordering

Purpose: make the solution approachable through indirect clues and provide an
intentional touch interaction for the safe's four-digit combination.

- Added a lightbulb in the header and safe panel. The read-only hint resolver
  follows current puzzle progress and item locations, including dropped equipment
  and carrying constraints. The safe hint may mention 1327 as requested.
- Added a themed four-slot keypad with clear, backspace, hardware keyboard
  support, and explicit submission. It opens for typed/menu commands and pending
  saved games; background controls cannot accidentally submit a wrong answer.
- Swapped W/E presentation order while preserving movement semantics.
- Added full-route hint/restore checks, safe interaction regressions, and phone,
  landscape, and enlarged-text layout coverage. See [design and validation
  notes](hints-and-safe.md) for decisions, source use, and tool experience.
- Validation: all 77 tests passed; `flutter analyze` reported no issues.
  Inspected rendered hint and safe panels with real fonts, including small-phone
  and enlarged-text layouts. No live-device update was performed.

## 2026-09-08 — Puzzle command discoverability and upstairs artwork

Purpose: make cross crafting and nail removal discoverable in the touch UI,
and restore the missing scene upstairs from the entrance hall.

- Replaced generic MAKE/REMOVE puzzle labels with MAKE CROSS on wire/bar pieces
  and REMOVE NAILS on the hatch. The hammer also exposes REMOVE NAILS in room 21.
  These actions use the normal engine command transaction, preserving puzzle
  prerequisites, turn accounting, and saves.
- Recovered room 9's complete 157-byte original drawing from the cassette.
  The legacy extractor started at room 1, although room 9 precedes it on tape;
  the compiled room 9 buffer was empty. Extended the tracked read-only
  `scripts/inspect_original.py` with `upstairs_hallway_bytecode_hex` so recovery
  is reproducible from the source cassette.
- Treat compiled room definitions as the runtime artwork source. The legacy
  `assets/rooms.bin` snapshot omits room 9's header and first 93 bytes; do not
  regenerate definitions from it. The local ignored extractor was corrected
  to locate the room 9 header; this is not a substitute for the tracked recovery
  evidence. The legacy generator also lacks current connection metadata.
- Rendering coverage now rejects empty artwork instead of silently skipping it.
  Added four-color hallway rendering, real inventory crafting, both nail-removal
  menus, and entrance-to-upstairs widget navigation coverage.
- Validation: the full 62-test suite passed, followed by the added upstairs
  navigation/render check. Inspected the widget-rendered hallway PNG; scene
  geometry and colors render correctly (test UI fonts were placeholders).
  No live-device update was performed. Static analysis reported no issues. Tooling required
  SDK-cache permission. Initial new test assumptions were corrected against
  engine rules: GO HATCH leads to room 20; the stairs require the carried Bible
  to overcome fear (the knife only helps with the rat). No game rules were
  changed to accommodate the tests.

## 2026-09-07 — Original game rules and solvability audit

Purpose: make the mobile adaptation solvable under the original constraints,
using the supplied walkthrough and original Atari BASIC/cassette as evidence.

- Extracted cassette DATA and exit bytes; resolved the transcription error that
  placed the dog in the corridor and hid the cellar door.
- Separated deterministic adventure rules from Flutter presentation/persistence.
  Restored six-unit inventory, four-unit iron, cumulative 199-turn candle life,
  cloak deaths, cellar-door trapping, chair reach, passage/table gating, crafting,
  holy-water consumption, safe deaths, and courtyard-only victory.
- Added schema-2 saves with ordered snapshot writes and legacy migration.
  Made the carrying badge and contextual puzzle menus reflect the rules.
- Replaced the permissive solution test with the constrained complete route;
  added boundary, negative-path, save/restore, and tap interaction regressions.
- Validation: `flutter test` passed all 45 tests, including the full walkthrough
  and restoration after every command. Static analysis found one existing unused
  `_hoverLocalPos` field in `lib/rendering/atari_render_controller.dart`; new rule
  code has no remaining diagnostics. No emulator or physical-device acceptance
  was claimed.

The [audit](game-logic-audit.md) records source line references, intentional
compatibility decisions, limitations, and tool failures for future work.

## 2026-09-07 — Visual refresh and live application update

Purpose: make the source-corrected game easier to read and play on phones and
desktop while preserving its original Atari artwork.

- Added a dark green/brass theme, framed room art, readable journal, explicit
  command submission, fuel/load indicators, responsive object and inventory
  controls, and fixed phone/short-landscape navigation.
- Added scrollable display settings, reduced-motion behavior, clearer terminal
  states, and confirmation before replacing an active game.
- Fixed blank scenes with animation disabled and removed the existing unused
  renderer field. Corrected duplicate room-description punctuation and journal
  command-prefix formatting.
- Validation: all 52 tests passed, including the full constrained walkthrough,
  saved-game continuity, interaction tests, six viewport/text-size scenarios, and
  instant rendering checks. `flutter analyze` reported no issues. Rendered PNGs
  were inspected and small-screen layout refinements rechecked.
- Applied the changes to the connected macOS app with a successful hot restart
  and subsequent hot reloads; no runtime errors were reported.

[Visual design notes](visual-design.md) record the layout decisions, screenshot
workflow, browser/driver limitations, and rendering fix.

## 2026-09-07 — Inventory icon redesign

Purpose: give inventory objects recognizable, consistent artwork at small sizes.

- Replaced tinted inventory bitmaps with 28 hand-drawn vector symbols, shared
  across inventory cards, room object chips, and contextual action dialogs.
  Increased inventory artwork to 36 pixels and differentiated item states with
  silhouettes and material colors. Preserved game rules, labels, and actions.
- Kept the rendering system code-native: one painter with a common grid and
  stroke convention, selected by `ObjectIcon`, without new asset dependencies.
- Added portable-item coverage, rendered state-distinction, and real inventory
  action tests. Inspected a rendered contact sheet at 36 and 20 pixels with a
  320-pixel inventory control. These are widget renders, not device screenshots.
- Validation: all 55 tests passed; `flutter analyze` reported no issues.
  Hot reload succeeded in the connected macOS app.

## 2026-09-07 — Exploration navigation alignment

Purpose: keep directional movement beside the exploration action rather than
detaching it at the left of a wide control surface.

- Right-aligned the shared wrapping navigation control. Its responsive wrapping
  behavior remains intact on narrow phones, while desktop movement now lines up
  with Look around at the right edge.

## 2026-09-07 — Room-side navigation and darkness feedback

Purpose: place navigation vertically beside the room, following the user's
classic adventure reference, and explain movement restrictions in darkness.

- Replaced the below-scene strip with a shared right-side rail containing Look
  around and six movement buttons. Sized the artwork frame to its actual aspect
  ratio rather than framing a wider letterboxed container.
- Enabled direction attempts in darkness through the normal command handler;
  retained the original cellar trap and added explicit broken-latch/door-prop
  guidance. Compact dark scenes use a symbol to avoid text overflow.
- Layout tradeoff: on phones navigation now scrolls with the room rather than
  occupying a fixed strip; the journal and command input remain outside that scroll.
- Validation: 59 tests passed, including dark cellar escape with a propped door,
  locked-door feedback without the prop, eight viewport/state renders, and aspect
  ratio/right-side placement assertions. Inspected desktop and phone renders.
