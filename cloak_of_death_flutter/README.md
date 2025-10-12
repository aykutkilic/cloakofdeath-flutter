# Cloak of Death - Flutter Implementation

A Flutter recreation of the classic text adventure game "Cloak of Death" originally written for 8-bit Atari computers by David Cockram.

## Features

### Implemented ✅
- **Vector Graphics Rendering**: Custom painter that renders room layouts from extracted cassette data
- **Game State Management**: Provider-based state management for rooms, inventory, and game flags
- **Retro UI**: Green-on-black terminal-style interface reminiscent of classic computer systems
- **Room Navigation**: Move between 27 different rooms
- **Basic Command System**: Text-based command input
- **Status Display**: Shows current room, inventory count (max 6 items), and move counter

### To Be Implemented 🚧
- Complete text parser for verb-noun commands (GET, DROP, OPEN, etc.)
- Full game logic (53 objects, 10 game flags, puzzles)
- Lighting system (dark rooms requiring candles)
- Win/death conditions and game completion
- Save/load game functionality

## Project Structure

```
lib/
├── models/
│   ├── vector_command.dart   # Vector drawing command data model
│   ├── room.dart              # Room data model
│   └── game_data.dart         # Game data loader
├── rendering/
│   └── vector_renderer.dart   # CustomPainter for room graphics
├── game/
│   └── game_state.dart        # Game state management with Provider
├── widgets/
│   └── room_view.dart         # Room visualization widget
└── main.dart                  # Main app and game screen

assets/
└── room_vectors.json          # Extracted room vector data
```

## How Vector Rendering Works

The game uses a custom vector drawing engine extracted from the original Atari cassette data:

1. **Data Extraction** (`extract_vectors.py`):
   - Parses binary cassette dump (blocks 117-195)
   - Extracts vector commands and converts to JSON
   - Commands include: move, line, poly_start, poly_end, etc.

2. **Vector Renderer** (`vector_renderer.dart`):
   - CustomPainter that interprets vector commands
   - Scales coordinates (0-255) to screen size
   - Draws lines, polygons, and shapes
   - Renders in retro green-on-black style

3. **Command Types**:
   - `move`: Move pen without drawing
   - `line`: Draw line from current position
   - `poly_start/poly_line/poly_end`: Polygon drawing
   - `curve/arc`: Curved lines (simplified as lines for now)

## Running the App

```bash
# Get dependencies
flutter pub get

# Run on your device/emulator
flutter run

# Run tests
flutter test
```

## Game Architecture

The original Atari BASIC game used:
- 27 locations (rooms)
- 53 objects (tracked in array P(53))
- Verb-noun command parser
- State flags (F1-F10) for puzzle progression
- 6-item inventory limit
- Lighting mechanic (candle burns out after ~200 moves)

This Flutter implementation recreates the same structure using modern patterns:
- Provider for state management
- JSON for data storage
- CustomPainter for vector graphics
- Material Design widgets with retro styling

## Development Notes

### Original Game Data Sources
- `Cloak of Death.bas` - Atari BASIC source code
- `cas_dump.txt` - Hexadecimal dump of cassette data
- `solution.txt` - Complete walkthrough
- `Cloak of death.drawio.png` - Visual map of all rooms

### Technical Details
- Coordinates: 0-255 range (Atari screen resolution)
- Text encoding: ATASCII in original, UTF-8 in Flutter
- Drawing commands: Based on Atari vector graphics system
- State persistence: SharedPreferences (to be implemented)

## Next Steps

1. **Implement Command Parser**:
   - Parse verb-noun syntax (e.g., "GET CANDLE")
   - Map verbs to actions (GO, GET, DROP, OPEN, etc.)
   - Handle object interactions

2. **Add Game Objects**:
   - Load object data from original game
   - Implement object placement and pickup
   - Track object states

3. **Implement Puzzles**:
   - Door locks and keys
   - Exorcism ritual
   - Light/dark rooms
   - Item combinations

4. **Testing**:
   - Use solution.txt to verify game completion
   - Test all 27 rooms
   - Validate puzzle logic

## Credits

- Original Game: David Cockram (Atari 8-bit)
- Flutter Implementation: 2025
- Data Extraction: Python cassette parser
- Vector Graphics: Converted from original binary format

## License

This is a preservation/educational project recreating a classic game.
