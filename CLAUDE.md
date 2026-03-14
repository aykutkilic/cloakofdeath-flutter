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

**Game logic engine** (`game/game_state.dart`): All game logic is monolithic in this single class — there is no separate rule engine or game_logic.dart. It contains:
- Verb/noun ID parsing (39 verbs, 53 nouns) that exactly emulates ATARI BASIC line 1400/14 behavior
- Command dispatch via hardcoded switch statements (`_dispatchLogic`)
- 10 boolean game flags (safe_open, cupboard_open, dog_terrified, door_unlocked, etc.)
- Object location tracking (~27 pickable/static objects), max 12 inventory items
- Candle countdown (300-move lifetime), dark room logic (rooms 25 & 26)
- 40-character text wrapping matching Atari 40-column display
- Save/load persistence via SharedPreferences (JSON serialization)

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

### Original Game Data

- **27 rooms** (IDs 1-27), **53 objects** tracked in array `P(53)`, **10 state flags** (F1-F10)
- Room connectivity is currently hardcoded in `GameState._roomConnections`
- Binary room graphics data: `assets/rooms.bin` (extracted from cassette chunks 117-195)
- JSON room data: `assets/room_vectors.json` (legacy format, rooms.bin is now primary)
- Custom Atari font: `assets/fonts/Atari-Regular.ttf`

### Tools (`tools/`, gitignored)

Contains original game data (`.bas`, `.cas`), reverse-engineered 6502 disassembly, analysis scripts, and Dart rendering debug tools. Key reference: `tools/disassemble/DRAW Algorithm.md` documents all 7 bytecode commands. This directory is gitignored.

## Testing

Tests are in `test/`. The primary test (`game_logic_test.dart`) is a **full walkthrough integration test** that executes the entire game solution sequentially — it validates room transitions, inventory management, state flags, and end-to-end game completion. There are no isolated unit tests for individual verb/noun parsing. `game_logic_comprehensive_test.dart` covers specific logic blocks (rat blocking, object examination).

## Key Technical Details

- The rendering bytecode uses a polyline state machine: first coordinate pair starts a polyline (vertex0), subsequent pairs draw connected lines. Commands >= 0xA1 are control codes, < 0xA1 are coordinate pairs.
- C9/CA commands close a polygon and flood fill using an offset byte encoding: high nibble = X offset, low nibble = Y offset, relative to vertex0.
- Atari aspect ratio: pixels are non-square (160×96 stretched to ~4:3 display). The renderer accounts for this.
- The original game uses ATASCII character encoding (not ASCII). The `.bas` file contains Unicode representations of ATASCII symbols.
- GET verb restricts noun IDs to ≤28, exactly matching original ATARI BASIC behavior — do not change this threshold.
- Verb ID 100 is a special "USE" bucket containing REMOVE, CUT, and other context-specific verbs.
