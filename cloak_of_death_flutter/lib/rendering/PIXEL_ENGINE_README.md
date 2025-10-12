# Atari Pixel Rendering Engine

A complete implementation of the Atari 65XE FIND graphics rendering system with authentic pixel-by-pixel rendering animation.

## Overview

This pixel rendering engine emulates the original Atari BASIC `FIND` function that renders room graphics from bytecode stored in the cassette tape data. The implementation includes:

- **Bytecode parser** for the FIND data format
- **Pixel-level rendering** using Bresenham's line algorithm
- **Scanline flood fill** with pattern support
- **Progressive animation** simulating the slow Atari 65XE rendering speed
- **Configurable render speed** (default: 20 pixels/second)

## Architecture

### Components

1. **`atari_bytecode_parser.dart`** - Parses FIND bytecode format
2. **`atari_pixel_renderer.dart`** - Renders pixels using Bresenham and flood fill
3. **`atari_render_controller.dart`** - Manages progressive animation
4. **`atari_pixel_demo.dart`** - Demo widgets and examples
5. **`pixel_engine_test.dart`** - Test application

## FIND Bytecode Format

The bytecode format matches the original Atari FIND routine:

```
Data buffer: 5388 bytes starting at offset 30000
Room markers: 0xA0 to 0xBB (room IDs 0-27)

Format:
  AA C1 C2 C3 C4 [commands...] FF
  |  |--------| |----------| |
  |     |           |        End marker
  |     |           Drawing commands
  |     4-color palette (Atari color bytes)
  Room ID (0xA0 + roomNumber)
```

### Drawing Commands

| Opcode | Command | Description |
|--------|---------|-------------|
| `C8` | Polyline | Draw polyline with current color |
| `C9` | Flood Fill | Flood fill last polyline + optional polyline |
| `CC` | Fill At | Flood fill at specific point with pattern/solid |
| `CD` | Polyline C0 | Draw polyline with palette color 0 |
| `CE` | Polyline C1 | Draw polyline with palette color 1 |
| `CF` | Polyline C2 | Draw polyline with palette color 2 |
| `D0` | Polyline C3 | Draw polyline with palette color 3 |

### Polyline Format

```
CD X1 Y1 X2 Y2 X3 Y3 ...
```

Coordinates are in Atari screen space (0-159 width, 0-95 height).

### Flood Fill Formats

**Solid Fill:**
```
CC AB XX YY
```
- If `AB <= 3`: Fill with solid palette color `AB`
- `XX YY`: Seed point coordinates

**Pattern Fill:**
```
CC AB XX YY
```
- If `AB > 3`: Fill with 4-column pattern
- Pattern byte `AB` format: `0bAABBCCDD` (2 bits per column)
- Each column uses a palette color index (0-3)
- Pattern repeats every 4 pixels: `color(x,y) = palette[pattern[x mod 4]]`

## Usage

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'rendering/atari_bytecode_parser.dart';
import 'rendering/atari_render_controller.dart';

// Load bytecode data (5388 bytes from cassette)
final Uint8List bytecodeBuffer = await loadFindData();

// Parse room data
final roomData = AtariBytecodeParser.parseRoom(bytecodeBuffer, roomId: 1);

if (roomData != null) {
  // Display with progressive rendering
  Widget roomView = AtariAnimatedRoomView(
    roomData: roomData,
    pixelsPerSecond: 20.0,  // Atari 65XE speed
    autoStart: true,
  );
}
```

### Manual Control

```dart
// Create controller
final controller = AtariRenderController(
  roomData: roomData,
  pixelsPerSecond: 20.0,
);

// Start animation
controller.startAnimation();

// Pause animation
controller.stopAnimation();

// Jump to end
controller.renderAll();

// Adjust speed
controller.setPixelsPerSecond(50.0);

// Get progress
double progress = controller.progress; // 0.0 to 1.0
```

### Custom Painter

```dart
// For manual rendering without animation
CustomPaint(
  painter: AtariPixelRenderer(
    roomData: roomData,
    maxCommandIndex: 5,      // Render first 5 commands
    maxPixelCount: 1000,     // Render first 1000 pixels
  ),
  child: SizedBox.expand(),
)
```

## Running Tests

### Test Application

Run the test application to see various rendering examples:

```bash
cd cloak_of_death_flutter
flutter run lib/rendering/pixel_engine_test.dart
```

This launches a test app with:
- Sample rectangle rendering
- Fast rendering demo (200 px/sec)
- Complex multi-shape scene
- Pattern fill demonstrations

### Creating Test Bytecode

```dart
import 'dart:typed_data';

Uint8List createTestRoom() {
  final buffer = <int>[];

  // Room marker (room 1 = 0xA1)
  buffer.add(0xA1);

  // Palette (4 Atari color bytes)
  buffer.add(0x00);  // Color 0: Black
  buffer.add(0x0F);  // Color 1: White
  buffer.add(0x48);  // Color 2: Red
  buffer.add(0x98);  // Color 3: Blue

  // Draw rectangle with color 1 (white)
  buffer.add(0xCE);  // Polyline color 1
  buffer.addAll([20, 20, 140, 20, 140, 76, 20, 76, 20, 20]);

  // Fill with color 2 (red)
  buffer.add(0xCC);  // Flood fill
  buffer.add(0x02);  // Solid color 2
  buffer.add(80);    // Seed X
  buffer.add(48);    // Seed Y

  // End marker
  buffer.add(0xFF);

  return Uint8List.fromList(buffer);
}
```

## Integration with Existing Code

### Adding to Room Model

The `Room` model already supports bytecode data:

```dart
Room myRoom = Room(
  id: 1,
  name: "Entrance Hall",
  description: "A dark entrance hall...",
  vectors: existingVectorCommands,
  exits: ["north", "east"],
  bytecodeData: findBytecode,  // Add bytecode here
);
```

### Toggle Between Renderers

```dart
class RoomWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return room.bytecodeData != null
      ? AtariAnimatedRoomView(
          roomData: AtariBytecodeParser.parseRoom(
            room.bytecodeData!,
            room.id
          )!,
          pixelsPerSecond: 20.0,
        )
      : CustomPaint(
          painter: VectorRenderer(room: room),
        );
  }
}
```

## Performance

### Rendering Speed

The default speed of **20 pixels/second** matches the approximate rendering speed of the Atari 65XE. Adjustable range: 1-10,000 px/sec.

### Pixel Counting

Pixels are counted for:
- **Line segments**: Manhattan distance (max of dx, dy)
- **Flood fills**: Each pixel filled

### Memory Usage

- 160×96 pixel buffer: ~60KB per room
- Bytecode data: Varies by room complexity (typically 100-500 bytes)

## Algorithm Details

### Bresenham's Line Algorithm

Fast integer-only line drawing without floating-point calculations, matching the efficiency of the original Atari implementation.

### Scanline Flood Fill

Stack-based scanline algorithm for efficient area filling:
1. Start from seed point
2. Fill horizontal spans
3. Track visited pixels to prevent re-processing
4. Add neighbor spans to stack

### Pattern Fill Implementation

4-column vertical pattern:
```
Pattern byte: 0b11100100
Columns:      [3][2][1][0]

X coord:  0 1 2 3 4 5 6 7 8 9 ...
Color:    0 1 2 3 0 1 2 3 0 1 ...
          ^-------^ repeating pattern
```

## Troubleshooting

### Room not rendering

1. Check bytecode buffer contains room marker (0xA0 + roomId)
2. Verify palette colors are valid Atari color bytes
3. Ensure coordinates are within bounds (0-159, 0-95)

### Slow performance

1. Increase `pixelsPerSecond` value
2. Use `renderAll()` to skip animation
3. Check flood fill seed points are valid (not causing huge fills)

### Colors look wrong

1. Verify palette bytes match Atari color format (HHHHLLLL)
2. Check color generation in `_generateColor()` function
3. Compare with `AtariColors.fromAtariByte()` output

## Future Enhancements

Possible improvements:

- [ ] Load FIND data directly from cassette file
- [ ] Export rendered frames as images
- [ ] Add debug visualization of bytecode commands
- [ ] Optimize flood fill for large areas
- [ ] Support for custom color palettes
- [ ] Recording/playback of render animations

## References

- Original Atari BASIC FIND routine: Machine code at offset 30000
- Atari color format: https://atariwiki.org/wiki/Wiki.jsp?page=Color%20names
- Bresenham's algorithm: Classic computer graphics line drawing
- Room bytecode data: Extracted from "Cloak of Death" cassette chunks 117-204
