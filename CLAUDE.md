# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains **Cloak of Death**, a faithful Flutter reimplementation of the classic text adventure game originally written in Atari BASIC for 8-bit Atari computers by David Cockram. Original game data (`.bas`, `.cas`, scripts, disassembly) lives in `tools/` (gitignored).

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run the app (mobile/desktop)
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Static analysis
flutter analyze
```

The project requires **Flutter SDK with Dart ^3.10.0-162.1.beta** (see `pubspec.yaml`).

## Architecture

### Flutter App (`lib/`)

**State management**: Provider pattern — `GameState` (ChangeNotifier) is the single source of truth for room, inventory, flags, and move count. Created in `main.dart` and consumed by all widgets.

**Game logic engine** (`game/adventure_engine.dart`): Pure Dart command parsing,
object locations, puzzle flags, conditional exits, and one turn-completion path.
Inventory is derived from locations, with six carrying units and four-unit iron.
The candle has 199 cumulative burning turns, including lighting; extinguishing
does not refill it. Indoor rooms 15–26 need a local lit candle for visibility.
The cloak and wrong safe combination can kill the player; room 27 is victory.

**Flutter adapter** (`game/game_state.dart`): `ChangeNotifier` API, 40-column text
wrapping, contextual actions, rendering preferences, and ordered SharedPreferences
saves. Schema 2 persists transient puzzle state; legacy saves migrate explicitly.
Read `docs/game-logic-audit.md` before changing rules or source interpretations.

**Rendering pipeline** (the most complex subsystem):
- `room_bytecode_loader.dart` — loads raw bytecode from `assets/rooms.bin` (extracted from original cassette)
- `atari_bytecode_parser.dart` — parses the FIND bytecode format into `AtariBytecodeCommand` objects (polylines, closed polygons, flood fills). Bytecode commands: C8-D0 range (see `tools/disassemble/DRAW Algorithm.md` for full spec)
- `atari_pixel_renderer.dart` — `CustomPainter` that renders commands pixel-by-pixel at authentic Atari resolution (160×96), using Bresenham line drawing and scanline flood fill
- `atari_render_controller.dart` — animation controller for progressive room rendering (pixel-by-pixel reveal effect)
- `atari_colors.dart` — Atari GTIA color palette mapping

**Auto-generated data** (`data/room_definitions.dart`): ~2,690-line file containing room bytecode data, generated from cassette extraction tools. Do not hand-edit.

**Widgets**:
- `room_view.dart` — main room graphics display using the pixel renderer
- `verb_panel.dart` / `object_panel.dart` — command input UI
- `interactive_inventory.dart` — inventory display
- `unified_minimap.dart` — room navigation minimap
- `game_settings_dialog.dart` — scrollable display settings
- `object_icon.dart` — shared pixel-asset icons and scenery glyphs

The visual design and responsive layout rules are documented in
`docs/visual-design.md`. Keep navigation reachable outside the scrolling scene on
phones and short landscape windows. Disabling animation must render immediately,
not leave an empty buffer. `test/ui_layout_test.dart` exercises the layouts and
can export rendered PNG previews.

### Original Game Data

- **27 rooms** (IDs 1-27), **53 objects** tracked in array `P(53)`, **10 state flags** (F1-F10)
- Base room connectivity comes from room definitions; `AdventureEngine.exits`
  projects conditional exits, including the pool-table-controlled west return.
- Binary room graphics data: `assets/rooms.bin` (extracted from cassette chunks 117-195)
- JSON room data: `assets/room_vectors.json` (legacy format, rooms.bin is now primary)
- Custom Atari font: `assets/fonts/Atari-Regular.ttf`

### Tools (`tools/`, gitignored)

Contains original game data (`.bas`, `.cas`), reverse-engineered 6502 disassembly, analysis scripts, and Dart rendering debug tools. Key reference: `tools/disassemble/DRAW Algorithm.md` documents all 7 bytecode commands. This directory is gitignored.

## Testing

Tests are in `test/`. `game_logic_test.dart` executes the complete walkthrough
without injecting state and verifies every pickup, carrying load, and victory.
`adventure_constraints_test.dart` covers fuel boundaries, prerequisites, deaths,
object transformations, aliases, and restoration after every walkthrough command.
`game_interaction_test.dart` exercises puzzle commands through actual tap menus.

## Key Technical Details

- The rendering bytecode uses a polyline state machine: first coordinate pair starts a polyline (vertex0), subsequent pairs draw connected lines. Commands >= 0xA1 are control codes, < 0xA1 are coordinate pairs.
- C9/CA commands close a polygon and flood fill using an offset byte encoding: high nibble = X offset, low nibble = Y offset, relative to vertex0.
- Atari aspect ratio: pixels are non-square (160×96 stretched to ~4:3 display). The renderer accounts for this.
- The original game uses ATASCII character encoding (not ASCII). The `.bas` file contains Unicode representations of ATASCII symbols.
- GET permits only original portable objects (BASIC noun IDs ≤28), including
  explicit names for state variants. Keep scenery nonportable.
- Do not trust `tools/Cloak of Death.bas` DATA verbatim: its transcription omits
  a zero and shifts the cupboard/desk/dog/door locations. The read-only script
  `scripts/inspect_original.py` extracts the authoritative cassette evidence.
