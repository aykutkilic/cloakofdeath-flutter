# Notes from Fable 5 — Room 8 rendering bug + full audit

Date: 2026-07-10

**Method:** Rendered room 8 with the actual engine (`AtariBytecodeParser` + `AtariPixelRenderer.renderAll`) into a PPM and compared it pixel-by-pixel against the original game running in Altirra, captured in `tools/atari000.avi` (frame ~75 shows the completed sitting room; capture maps 1:1 vertically, `atari_y = capture_y − 24`, `atari_x = (capture_x − 8) / 2`). The app screenshot matches the engine output exactly (differences vs. the app are only screenshot scaling artifacts), so all deviations below are engine-vs-original, not app-vs-engine.

---

## Rendering issues

### R1. CB/CC flood fill uses the wrong algorithm — THE room 8 back-wall bug (CONFIRMED — **FIXED 2026-07-10**)

> **Fix applied:** parser now stamps the current draw color on CB/CC commands; `_drawBoundaryFill` in `atari_pixel_renderer.dart` does a boundary fill (stop at current draw color, down-only scanline) with solid/pattern support for all of C9/CA/CB/CC. Room 8 vs. the Altirra capture: 158 → 9 mismatching pixels. Regression test: `test/rendering_fill_test.dart`.

`AtariPixelRenderer._drawFillAtXY` (lib/rendering/atari_pixel_renderer.dart:232) implements CB/CC as a **seed-color-match** fill: it reads the pixel at the seed and only replaces pixels equal to it.

The original fill routine ($8BA3, see `tools/disassemble/FILL_ROUTINE_ANALYSIS.md`) is a **boundary fill**: it fills every pixel until it hits a pixel of the **current drawing color** (`$06F2`, the color set by the last C8/CD/CE/CF/D0 command) — exactly the same boundary rule the C9/CA path (`_drawScanlineFillSolid`) already uses.

The two agree whenever the region interior is a single uniform color, which is why most rooms are pixel-perfect. They diverge when the region contains multiple colors:

- **Room 8** (sitting room): `CC 64 3F 1A` (pattern [1,2,1,0], seed (63,26)). At that point the current color is 0 (black, set by the `CD` left-door command). The original floods from the color-2 door-frame line through the color-3 doorway interior, stopping at black — painting the open-doorway area (x≈70–80, y=26–39, down to the black line `C8 46 28 50 28`) with orange/gray/black stripes. Our renderer only repaints the 1-px door-frame top line, leaving the doorway solid gray. **This is the wrong "flood fill at the back" in the screenshot.**
- Verified empirically: with boundary-fill semantics, room 8 mismatches vs. the Altirra capture drop from **158 px to 9 px** (the remainder is capture-alignment noise on stripe edges).
- Rooms affected by the semantic difference (old vs. boundary fill, same data): room 8 = 149 px, **room 10 = 375 px**, rooms 5 and 7 = 1 px each. Room 10 (guest bedroom) is therefore almost certainly also rendering wrong today.

**Fix sketch:** track the current draw color in the parser and stamp it on `floodFillAt` commands (`colorIndex` is currently `null` for CB/CC), then make `_drawFillAtXY` fill "while `peek != borderArgb`" (border = current color) instead of "while `peek == emptyColor`", keeping the existing down-only scanline shape (that part matches the original).

### R2. `CA` with a pattern byte crashes the renderer in 9 rooms (CONFIRMED CRASH — **FIXED 2026-07-10**)

> **Fix applied:** CA's byte is now decoded like CC's (≤3 solid, >3 pattern) through the same `_drawBoundaryFill` path. All 26 rooms render without throwing; the 9 affected rooms now draw complete scenes. Covered by `test/rendering_fill_test.dart`.

`renderCommands` does `roomData.palette[cmd.fillPattern!]` for closed-polyline fills (lib/rendering/atari_pixel_renderer.dart:123). The CA color byte is **not** limited to 0–3 — it uses the same encoding as CC (≤3 = solid palette color, >3 = 4-column pattern). The shipped room data contains:

| Room | Command | Decoded pattern |
|------|---------|-----------------|
| 11 Dressing Room | `CA 80 11` | [2,0,0,0] |
| 13 Master Bedroom | `CA 72 11`, `CA 20 11`, `CA 08 11` | [1,3,0,2], [0,2,0,0], [0,0,2,0] |
| 15 Haunted Room | `CA 44 11` | [1,0,1,0] |
| 16 Library | `CA 11 11` / `CA 44 11` ×8 | [0,1,0,1] / [1,0,1,0] |
| 18 Sewing Room | `CA 04 11` | [0,0,1,0] |
| 21 Pool Room | `CA 74 11` | [1,3,1,0] |
| 22 Wine Cellar | `CA 08 11` | [0,0,2,0] |
| 23 Cold Damp Cellar | `CA 44 01`, `CA CC 11` | [1,0,1,0], [3,0,3,0] |
| 26 Dark Tunnel | `CA D0 11` | [3,1,0,0] |

Rendering any of these rooms throws `RangeError (length): Invalid value: Not in inclusive range 0..3` inside the render loop — in the app the progressive animation dies mid-room, so these rooms display half-drawn. (Rooms >14 are usually hidden behind "TOO DARK TO SEE", which masks this, but rooms 11 and 13 are lit and always reachable.)

**Fix sketch:** treat the CA byte like the CC `AB` byte — solid if ≤3, otherwise `decodePattern`, and fill with the boundary rule from R1.

### R3. Hand-edited fill offsets in `room_definitions.dart` diverge from `assets/rooms.bin`

The "auto-generated, do not hand-edit" data no longer matches the cassette extraction. All diffs are C9/CB offset/seed bytes:

- room 2 @44: `10→11` · room 5 @119: `01→11` · room 7 @189: `00→10`, @217: `10→11`, @232: `11→12` · room 8 @15: `10→11` · room 14 @103: `01→11`, @146: `00→11` · room 23 @70,80: `10→11` · room 27 @71,79: `01→11`

These look like workarounds for a fill-algorithm quirk: with the original bytes the seed often lands **on** the polygon's border line, and our `_drawScanlineFillSolid` then fills nothing (the very first `peek == border` check fails). The original hardware routine fills those regions fine (visible in the video — e.g. room 8's hearth base, `C9 10`). Once the fill handles seed-on-border like the original, the data should be reverted to the rooms.bin bytes. Also note `RoomBytecodeLoader` no longer reads `assets/rooms.bin` at all (data is compiled into Dart); CLAUDE.md still describes rooms.bin as primary.

### R4. Palette mapping is measurably off

Measured from the Altirra capture vs. `_generateColor` (lib/rendering/atari_bytecode_parser.dart:662):

| Atari byte | Original (Altirra) | Ours |
|------------|--------------------|------|
| `0x18` (hue 1, lum 8) | (144, 97, 36) orange-tan | (79, 51, 25) dark muddy brown |
| `0x04` (hue 0, lum 4) | (51, 51, 51) | (73, 73, 73) |
| `0x08` (hue 0, lum 8) | (104, 104, 104) | (146, 146, 146) |

Grays scale linearly at ≈ lum × 12.75 in the reference; our `lum / 14.0 * 255` is ~40% too bright. Hue 1 should be a bright gold/orange family, not dark brown. Every room's floor/walls are visibly the wrong shade because of this.

### R5. Minor renderer notes

- `_drawFillAtXY`: the `if (emptyColor == 0) return;` guard only triggers for out-of-bounds seeds (peek returns 0); after `fillScreenPattern` no on-screen pixel is ever ARGB 0. Harmless but misleading.
- Room 9 (Upstairs Hallway) has empty bytecode in both the Dart data and rooms.bin; the app shows "Room 9 has no graphics data". The reference video never displays room 9, so whether the original reuses another room's graphic is unverified.
- Progressive rendering was verified identical to `renderAll` (0 pixel diff), so the animation path itself is not a source of divergence.

---

## Game logic issues

### L1. Room descriptions are missing their flavor sentences (user-visible in the screenshot)

Original descriptions are single strings (see `tools/all_strings.txt` lines ~726–746). The Dart data truncates several:

| Room | Original (missing part in bold) |
|------|--------------------------------|
| 5 | in a dark eerie corridor**.A rat scurries off into the distance** |
| 8 | in a large sitting room**.You can hear someone walking around upstairs** |
| 15 | in a haunted room**.It's icy cold and dark.A shiver passes up your back** |
| 19 | standing in a creaky attic**.You can hear footsteps from below** |
| 24 | in an old garage**.An accrid stench pervades the air** |

The screenshot's sitting room omits "You can hear someone walking around upstairs." — confirmed present in the original video at the same game state.

### L2. Room 1 description double period

`room_definitions.dart:31` is `'in a dark hall.'` (trailing dot) and `describeCurrentRoom` appends another → "You are in a dark hall..". All other rooms have no trailing dot.

### L3. `exits` metadata in `room_definitions.dart` is wrong/dead

`GameState.getAvailableExits()` and the minimap use `connections` only; the `exits` lists disagree with `connections` in most rooms (e.g. room 3 Kitchen: `exits: ['E','N','W']` vs actual `{'S': 2}`; room 1 omits `U`; room 8 lists a nonexistent `E`). Either regenerate `exits` from `connections` or delete the field.

### L4. GET WATER consumes the GOBLET — original keeps it

`_dispatchLogic` v3/o28 removes GOBLET from inventory and adds WATER/HOLY WATER. The original walkthrough (`tools/solution.txt`) performs `DROP GOBLET` near the end-game, which proves the goblet survives filling in the original. In our version that command would fail ("You aren't carrying it!!"); the repo's walkthrough test was adapted around this instead of matching the published solution.

### L5. LIGHT CANDLE fallback message is wrong

`v == 8` else-branch always prints "It's already lit!!" — including LIGHT CANDLE when you have no matches, or no candle at all.

### L6. Darkness check ignores a lit candle lying in the room

BASIC line 400: `IF L>C14 AND P(C9)<>H AND P(C9)<>L THEN F1=C1` — the room is lit if the lit candle is held **or in the room**. `isTooDarkToSee` only checks inventory, so dropping the lit candle in a dark room incorrectly blacks out the screen (and the dropped "LIT CANDLE" also isn't in `_objectLocations`' initial map, it's added ad hoc).

### L7. Move counter double-increments on movement

`processCommand` does `_moveCount++` for every command, and `moveInDirection` / the GO CORRIDOR / GO DOOR / GO PASSAGEWAY / GO HATCH / GO ANNEXE branches each do `_moveCount++` again → movement counts 2 moves, other commands 1. (Candle life is decremented separately and only once, so this is cosmetic for now.)

### L8. `getAvailableActionsForObject` location hints are wrong

It offers GET for `SAFE` at room 4, `DOOR` at rooms 2/6, `GATE` at room 7. Actual game locations: SAFE appears wherever the painting is dropped (room 15 on the solution path), the unlockable DOOR is at room 5, the GATE at room 26. All three are also scenery nouns (>28) that the GET logic rejects anyway, so the buttons offered can never succeed.

### L9. Message/flow drift vs. original (cosmetic, from the reference video)

- Ours: "I'm too scared. It looks very creepy!!" — original: "I'm too scared.It looks very creepy!".
- CONGRATULATIONS text prints at `UNLOCK GATES`; in the original solution the final `E` into the courtyard ends the game (exact original timing unverified).
- Prompt echo "What shall I do?E" matches the original exactly (not a bug).

### L10. Suspected: CLIMB CHAIR puzzle gate missing

The original solution carries the wicker chair to the kitchen and does `DROP CHAIR, ... CLIMB CHAIR, GET MATCHES` — strongly implying GET MATCHES (cupboard) requires standing on the chair. Our GET MATCHES has no such gate; CLIMB CHAIR only prints a message. Puzzle is bypassable. (BASIC gating not yet extracted — verify against the `.bas` before fixing.)

### L11. Suspected: "GET KEY" for the gate key

After `EXAMINE SAFE` the original solution types `GET KEY` to take the gate/skeleton key. Our nouns map `KEY`→19 (small cellar key) and only `GATE KEY`/`SKEL`→20, so `GET KEY` at the safe answers "I don't see it here" and the player must type `GET GATE KEY`. Check the original 4-char noun table resolution order.

---

## Repro / verification notes

- Engine output vs original: render a room to PPM via `AtariPixelRenderer.renderAll` in a `flutter test`, extract `tools/atari000.avi` frames with ffmpeg (1 fps; sitting room ≈ frame 75), map coordinates as described in the header, classify pixels to the 4-color palette per source before diffing.
- R1 numbers: seed-match fill = 158 mismatching pixels vs capture; boundary fill (border = current draw color, same down-only scanline) = 9.
- R2: calling `renderAll` for rooms 11, 13, 15, 16, 18, 21, 22, 23, 26 throws immediately; `flutter test` with a room-sweep reproduces in seconds.
