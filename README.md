# Cloak of Death - Flutter

A faithful Flutter recreation of **Cloak of Death**, a classic text adventure game originally written for 8-bit Atari computers by David Cockram.

## Features

- **Authentic Atari pixel rendering** from original cassette bytecode (160x96 resolution, Bresenham lines, scanline flood fill)
- **Complete game logic** — 27 rooms, 53 objects, 10 state flags, all puzzles fully implemented
- **39 verbs / 53 nouns** — exact emulation of the original ATARI BASIC parser
- **Progressive room animation** — pixel-by-pixel reveal effect with configurable speed
- **Interactive UI** — tap objects/inventory for verb popup, collapsible floating navigation in portrait mode
- **Responsive layout** — landscape and portrait orientations with adaptive navigation
- **Configurable aspect ratio** — Atari (160:96), 4:3, 16:9, or custom
- **Save/load** via SharedPreferences
- **Dark room mechanic** — candle with 300-move lifetime
- **Full walkthrough test** — automated end-to-end game completion test

## Running

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

Requires **Flutter SDK with Dart ^3.10.0-162.1.beta**.

## Architecture

- **State**: Provider pattern with `GameState` (ChangeNotifier) as single source of truth
- **Rendering**: Binary bytecode from `assets/rooms.bin` -> `AtariBytecodeParser` -> `AtariPixelRenderer` (CustomPainter) with progressive animation via `AtariRenderController`
- **Game logic**: Monolithic in `lib/game/game_state.dart` — verb/noun ID parsing, command dispatch, object tracking, flag management
- **Room data**: Auto-generated `lib/data/room_definitions.dart` (~2,690 lines) from cassette extraction

## Credits

- **Original Game**: David Cockram (Atari 8-bit)
- **Flutter Implementation**: 2025

## License

This is a preservation/educational project recreating a classic game.
