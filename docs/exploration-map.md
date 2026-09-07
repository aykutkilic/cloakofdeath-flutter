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
darkness has an unnamed card until seen in light. Hover/long press shows known
objects currently located in the room, using authoritative object locations so
pickups, drops, transformations, and consumed objects do not leave stale lists.
Objects still hidden by a puzzle are not disclosed. New games clear discovery.

## Geography and layout

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

Map travel feels immediate but follows the normal movement transactions. A BFS
executes candidate movement commands on cloned engines and admits only visited
destinations reached without death. This reuses rat, Bible, cellar latch, passage,
annexe, hatch, gate, candle, and cloak logic. The search performs no item or puzzle
actions and does not reveal unknown rooms along a shortcut. It is disabled while
the safe awaits a combination and after the game ends.

Search keys include room, object state, flags, and cloak progress. Shorter paths
to the same physical state dominate longer paths, including remaining candle
fuel. Path length is bounded by the discovered room count. The UI indicates
the number of turns or a blocked route. Clicking revalidates against current
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
cardinal/floor relationships, hint rotation, mouse hover, click travel, and
desktop/phone/landscape map layouts. Preview files use the existing PREVIEW_DIR
and PREVIEW_FONT test options. SDK-cache access needs sandbox escalation.
