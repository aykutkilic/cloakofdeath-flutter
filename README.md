# Cloak of Death - Flutter

A faithful Flutter recreation of **Cloak of Death**, a classic text adventure game originally written for 8-bit Atari computers by David Cockram.

## Features

- **Authentic Atari pixel rendering** from original cassette bytecode (160x96 resolution, Bresenham lines, scanline flood fill)
- **Source-checked game logic** — 27 rooms, the original puzzle chain, carrying constraints, and fatal hazards
- **Adventure parser** — original command abbreviations plus explicit names for mobile object actions
- **Progressive room animation** — pixel-by-pixel reveal effect with configurable speed
- **Atmospheric UI** — dark green panels, warm brass accents, readable journal, and original Atari artwork
- **Responsive layout** — a desktop scene/journal split, fixed phone navigation, keyboard-aware input, and scrollable inventory
- **Configurable aspect ratio** — Atari (160:96), 4:3, 16:9, or custom
- **Save/load** via SharedPreferences
- **Dark room mechanic** — 199 cumulative candle-burning turns; extinguishing pauses fuel use
- **Six carrying units** — ordinary objects cost one unit; the iron costs four
- **Accessible controls** — labeled actions, 48-pixel touch targets, scalable text, reduced-motion support, and instant scene rendering
- **Full walkthrough tests** — end-to-end completion, save/restore at every step, and constraint regressions

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
- **Game logic**: `lib/game/adventure_engine.dart` owns deterministic rules, object locations, conditional exits, and turn accounting. `GameState` adapts it to Flutter and serializes saves.
- **Room data**: Auto-generated `lib/data/room_definitions.dart` (~2,690 lines) from cassette extraction

Source evidence, deliberate compatibility decisions, and validation are in
[the game logic audit](docs/game-logic-audit.md). Dated changes are recorded in
[development history](docs/development-history.md).

## Credits

- **Original Game**: David Cockram (Atari 8-bit)
- **Flutter Implementation**: 2025

## License

This is a preservation/educational project recreating a classic game.
