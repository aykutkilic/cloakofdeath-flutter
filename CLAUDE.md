# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains **Cloak of Death**, a classic text adventure game originally written in Atari BASIC for 8-bit Atari computers by David Cockram. It has two main components:
1. **Original game preservation** — Atari BASIC source (`Cloak of Death.bas`), cassette image (`.cas`), solution walkthrough, and game maps
2. **Flutter mobile recreation** — A faithful Flutter reimplementation in `cloak_of_death_flutter/` with authentic Atari-style vector/pixel rendering

## Build & Run Commands

All Flutter commands must be run from `cloak_of_death_flutter/`:

```bash
cd cloak_of_death_flutter

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

# Run standalone Dart tool scripts (used for rendering debugging)
dart run tools/test_render_png.dart
```

The project requires **Flutter SDK with Dart ^3.10.0-162.1.beta** (see `pubspec.yaml`).

## Architecture

### Flutter App (`cloak_of_death_flutter/lib/`)

**State management**: Provider pattern — `GameState` (ChangeNotifier) is the single source of truth for room, inventory, flags, and move count. Created in `main.dart` and consumed by all widgets.

**Rendering pipeline** (the most complex subsystem):
- `room_bytecode_loader.dart` — loads raw bytecode from `assets/rooms.bin` (extracted from original cassette)
- `atari_bytecode_parser.dart` — parses the FIND bytecode format into `AtariBytecodeCommand` objects (polylines, closed polygons, flood fills). Bytecode commands: C8-D0 range (see `disassemble/DRAW Algorithm.md` for full spec)
- `atari_pixel_renderer_fixed.dart` — `CustomPainter` that renders commands pixel-by-pixel at authentic Atari resolution (160×96), using Bresenham line drawing and scanline flood fill
- `atari_render_controller_v2.dart` — animation controller for progressive room rendering (pixel-by-pixel reveal effect)
- `atari_colors.dart` — Atari GTIA color palette mapping

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

### Disassembly (`disassemble/`)

Contains reverse-engineered 6502 assembly of the original Atari DRAW and FILL routines. Key reference: `DRAW Algorithm.md` documents all 7 bytecode commands and the state machine. This is the authoritative spec for the Flutter rendering pipeline.

### Tools (`cloak_of_death_flutter/tools/`)

Standalone Dart scripts for debugging room rendering. `extract_rooms_from_cas.py` extracts room binary data from the cassette image. The `test_room8_fill*.dart` files are iterative debugging scripts for the flood fill algorithm.

## Key Technical Details

- The rendering bytecode uses a polyline state machine: first coordinate pair starts a polyline (vertex0), subsequent pairs draw connected lines. Commands >= 0xA1 are control codes, < 0xA1 are coordinate pairs.
- C9/CA commands close a polygon and flood fill using an offset byte encoding: high nibble = X offset, low nibble = Y offset, relative to vertex0.
- Atari aspect ratio: pixels are non-square (160×96 stretched to ~4:3 display). The renderer accounts for this.
- The original game uses ATASCII character encoding (not ASCII). The `.bas` file contains Unicode representations of ATASCII symbols.
