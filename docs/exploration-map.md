# Exploration map and hint rotation — 2026-09-08

Purpose: make repeat hints useful and let players inspect and revisit the parts
of the house they have discovered.

## Discovery and room information

`ExplorationMap` stores visited rooms, rooms seen in light, known objects, and
traversed connections. It lives beside the engine in `GameState` and is serialized
under the additive `exploration` save field. Engine schema 2 stays intact.
Legacy saves initialize knowledge from the current room only; inventory and
puzzle flags are not evidence that the player visited every related room.

Unvisited rooms have no card, name, contents, or floor entry. A room entered in
darkness has an unnamed card until seen in light. Mouse hover or touch tap shows known
objects currently located in the room, using authoritative object locations so
pickups, drops, transformations, and consumed objects do not leave stale lists.
Objects still hidden by a puzzle are not disclosed. New games clear discovery.

## Geography and layout

Compact-map revision: nodes now measure 48 by 48 pixels and show short names
only. Unused coordinate rows/columns collapse without changing compass order.
Grid pitch is 88 pixels horizontally and 96 vertically. Details live in bounded
hover/tap tooltips rather than a permanent panel; U/D links also keep
their full destination names in tooltips. Short names never disclose dark rooms.

The authored coordinate table is presentation data, independent of movement
legality. North is up, west is left, and floors encode vertical relationships.
All engine cardinal connections are tested against coordinate order; U/D pairs
share horizontal coordinates across different floors. Same-floor room positions
are unique. Long northward connections at the entrance use different lengths:
the dark corridor and conservatory cannot occupy the same map cell.

Only traversed connections are drawn. Arrowheads preserve observed direction;
cross-floor links carry U/D labels and switch the floor view without moving the
player. Connectors detour around intermediate cards, notably the entrance hall
to conservatory line beside the dark corridor. The canvas uses a readable initial
zoom centered on the current room when an overview would shrink cards too far;
it supports pan/zoom, zoom buttons, and a Fit floor control. A floor dropdown keeps the active
floor visible on phones; a horizontal chip strip initially hid it offscreen.

The header map button stays visible on phones. Display settings moves into the
game menu at narrow widths to keep the existing header footprint.

## Travel semantics

Touch input separates inspection from travel: a single tap opens the room
tooltip, while double-tap or long press requests travel. Mouse input retains
hover inspection and single-click travel. This is selected from the actual
pointer kind, not screen width or platform, so mobile browsers and mixed-input
devices behave consistently. Current and unreachable rooms remain inspectable;
travel gestures on them only show details. Tooltips are dismissed before travel.

Map travel feels immediate but follows the normal command transactions. A
turn-ordered search executes candidate commands on cloned engines and admits only visited
destinations reached without death. This reuses rat, Bible, cellar latch, passage,
annexe, hatch, gate, candle, and cloak logic. Beyond candle management, the search
performs no item or puzzle actions and does not enter unknown rooms along a shortcut. It is disabled while
the safe awaits a combination and after the game ends.

### Automatic candle management

Map routes include ordinary `LIGHT CANDLE` and `EXTINGUISH CANDLE` commands.
Before entering darkness, light a carried candle only with carried matches and
remaining fuel. Keep it burning between dark rooms. Extinguish before moving
between bright rooms, or immediately after leaving darkness. Leaving darkness
first avoids spending an extra turn inside the haunted bedroom. The final exit
is an exception: extinguish before winning, since terminal games accept no more
commands. The engine owns the shared room-light requirement used by the adapter
and planner; room names and artwork are not lighting rules.

These actions cost normal turns and lighting consumes fuel immediately. Fuel is
never reset; a candle can burn out en route. Missing equipment does not conjure
light or trigger failed automatic commands: the engine's existing ability to
navigate discovered rooms in darkness remains available. Dropped candles are
not picked up or extinguished remotely. Ordinary manual movement is unchanged.

Preview and execution share the exact command plan, including candle actions.
The search uses turn-cost buckets rather than movement-only BFS because candle
actions make edges have different costs. Search keys include room, object state,
flags, and cloak progress; each state retains non-dominated turn/fuel alternatives.
A route is pruned only when another reaches the same state in no more turns with
at least as much fuel. This also prevents fruitless cycles without a room-count
limit that would incorrectly count lighting commands as rooms visited. The UI indicates
the number of turns or a blocked route. Requesting travel revalidates against current
state before executing the selected route through `processCommand`, preserving
turns, candle consumption, entry effects, journal output, ordered saves, and
discovery updates. Map previews and floor switching do not change game state.

## Hint rotation

The deterministic primary hint remains the source of puzzle selection. Each
puzzle has an alternate clue that describes a different relationship or angle.
`takeHint` cycles these per-puzzle clues within the session, including reopening
the lightbulb dialog. Another hint cycles without closing the dialog. Rotation
does not advance puzzle progress, consume turns or fuel, or write journal entries.
Resetting starts a new rotation; rotation offsets are not canonical save data.

The earlier read-only `nextHint` API is kept for callers needing a stable preview.
The safe's variants can include 1327, following the user's earlier instruction.

## Validation

Regression coverage includes save migration/reset, unknown/dark room privacy,
current room contents, route preview purity, manual-equivalent travel turns,
locks and required equipment, entry side effects, fatal cloak routes, exact
cardinal/floor relationships, hint rotation, mouse hover/click, touch inspection,
double-tap/long-press travel, blocked touch travel, and
desktop/phone/landscape map layouts. Candle-specific tests compare saved state
against the same manual commands, exercise repeated light boundaries, one-turn
and exhausted fuel, missing/remote equipment, extra-turn cloak hazards, the final
exit, and route selection by total command cost. Preview files use the existing PREVIEW_DIR
and PREVIEW_FONT test options. SDK-cache access needs sandbox escalation.
