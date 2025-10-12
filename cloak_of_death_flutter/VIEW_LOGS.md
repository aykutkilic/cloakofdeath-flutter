# How to View Bytecode Parsing Logs

The bytecode parser now includes detailed logging that shows:
- Which room is being parsed
- Where the room data starts and ends
- Why parsing stops (next room marker, end marker, etc.)
- All commands parsed with their details
- Byte positions and hex values

## Viewing Logs in Flutter App

### Option 1: Terminal Output
Run the app with verbose output to see logs in the terminal:

```bash
flutter run -v
```

Look for lines starting with `[AtariBytecode]` in the terminal output.

### Option 2: Flutter DevTools
1. Run the app normally:
   ```bash
   flutter run
   ```

2. Open Flutter DevTools (the URL is shown when you run the app)

3. Go to the "Logging" tab to see all debug output

4. Filter by "AtariBytecode" to see only parser logs

### Option 3: Xcode Console (macOS)
If running on macOS:

1. Open Xcode
2. Go to Window → Devices and Simulators
3. Select your device/simulator
4. Click "Open Console" button
5. Filter by "AtariBytecode"

## Example Log Output

When you switch rooms or start the app, you'll see logs like:

```
[AtariBytecode] ========================================
[AtariBytecode] PARSING ROOM 1
[AtariBytecode] ========================================
[AtariBytecode] Found room marker 0xA1 at position 123
[AtariBytecode] Room 1: Header at position 123
[AtariBytecode] Room 1:   Palette: 0x0E, 0x56, 0xC8, 0xFA
[AtariBytecode] Room 1: Data range [128, 456), length=328 bytes
[AtariBytecode] Room 1: Stop reason: next room marker 0xB0 (room 16)
[AtariBytecode] Room 1: Starting command parsing at position 128, end at 456
[AtariBytecode] Room 1: [pos=128] byte=0xCD
[AtariBytecode] Room 1: CMD#1 CD Polyline: color=0, 12 points
[AtariBytecode] Room 1: [pos=153] byte=0xCA
[AtariBytecode] Room 1: CMD#2 CA Closed Polyline: color=0, 8 points
[AtariBytecode] Room 1: [pos=170] byte=0xC9
[AtariBytecode] Room 1: CMD#3 C9 Flood Fill: color=0
[AtariBytecode] Room 1: Stopping at position 455, byte=0xB0 (unknown/stop)
[AtariBytecode] Room 1: Parsed 3 commands
```

## Understanding the Logs

### Stop Reasons
- **"next room marker 0xXX (room Y)"** - Found the start of another room's data
- **"explicit end marker 0xFF"** - Found end-of-data marker
- **"end of buffer"** - Reached the end of the entire buffer

### Command Types
- **C8** - Polyline with current color
- **CA** - Closed polygon (no fill)
- **C9** - Flood fill last polyline
- **CC** - Flood fill at specific point
- **CD/CE/CF/D0** - Polyline with color 0/1/2/3

## Debugging Premature Rendering

If a room's rendering stops early:

1. Look for the "Stop reason" log
2. Check if it's stopping due to a room marker appearing too early
3. Compare the "Data range" length with expected size
4. Count the commands parsed vs. expected commands
5. Look for "Stopping at position X" to see what byte caused the stop

## Disabling Logs

To disable logging, edit `lib/widgets/room_view.dart` and change:

```dart
final roomData = AtariBytecodeParser.parseRoom(bytecode, room.id, enableLogging: true);
```

to:

```dart
final roomData = AtariBytecodeParser.parseRoom(bytecode, room.id, enableLogging: false);
```
